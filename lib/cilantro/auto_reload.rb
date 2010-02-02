#!/usr/bin/env ruby
require 'cilantro/FileMonitor'

String::ALPHANUMERIC_CHARACTERS = ('a'..'z').to_a + ('A'..'Z').to_a
def String.random(size)
  length = String::ALPHANUMERIC_CHARACTERS.length
  (0...size).collect { String::ALPHANUMERIC_CHARACTERS[Kernel.rand(length)] }.join
end

class IO
  def self.slurp(io, boundary)
    # puts "slurping..."
    msg = ''
    loop do
      begin
        event = select([io],nil,nil,0.5)
      rescue IOError
        next
      end

      if event.nil? # nil would be a timeout, we'd do nothing and start loop over. Of course here we really have no timeout...
      else
        event[0].each do |io| # Iterate through all sockets that have pending activity
          if io.eof? # Socket's been closed by the client. This is a safe question because if it's true, we must have been triggered by its closing.
          else
            begin
              if io.respond_to?(:read_nonblock)
                # puts "read_nonblock"
                100.times do
                  data = io.read_nonblock(1)
                  msg += data
                  if msg =~ /#{boundary}$/
                    msg.slice!(boundary)
                    return msg
                  end
                end
              else
                # puts "sysread"
                100.times do
                  data = io.sysread(1)
                  msg += data
                  if msg =~ /#{boundary}$/
                    msg.slice!(boundary)
                    return msg
                  end
                end
              end
            rescue Errno::EAGAIN, Errno::EWOULDBLOCK, EOFError => e
              # no-op. This will likely happen after every request, but that's expected. It ensures that we're done with the request's data.
              # puts " finerror #{e.inspect}"
            rescue Errno::ECONNRESET, Errno::ECONNABORTED, Errno::ECONNREFUSED, IOError => e
              # puts " finerror #{e.inspect}"
            end
          end
        end
      end
    end
  end
end

module Cilantro
  class AutoReloader
    include Rack::Utils

    class AppProcess
      def initialize(from_parent, to_parent, boundary, stdout, stderr)
        # (these are IO's)
        @from_parent = from_parent
        @to_parent = to_parent
        @boundary = boundary
        @stdout = stdout
        @stderr = stderr

        trap('INT') {
          # @stdout.puts "Child #{Process.pid} exiting!"
          @to_parent.close
          @from_parent.close
          exit! 0
        }

        $stderr.close
        $stderr = @stderr
        Cilantro.auto_reload = false # now that we're inside the auto-reloader, we want Cilantro to act normal.
        Cilantro.instance_variable_set(:@config_loaded, false)
        Cilantro.instance_variable_set(:@force_no_auto_reload, true)
        Cilantro.load_environment
        Cilantro.auto_reload = false # reset auto_reload again as the configuration probably turned it back on.
        $stdout.close
        $stdout = @stdout
        run_event_loop
      end

      def run_event_loop
        # Wait for messages, echo them back.
        loop do
          begin
            # puts "[C] Ready for next request..."
            request = IO.slurp(@from_parent, @boundary)
            # puts "[C] Slurped: #{request.inspect}"
            env = JSON.load(request)
            # puts "[C] Received: #{env.inspect}"
            env['rack.input'] = StringIO.new(env['rack.input'])
            env['rack.errors'] = $stderr
            # puts "[C] Processing request."
            received_message(env)
          rescue Object => e
            puts "ERROR: #{e.inspect}\n#{e.backtrace.join("\n")}"
          end
        end
      end

      def received_message(env)
        # Automatically loads app if not already loaded.
        # puts "[C] Calling app (#{Cilantro.app.inspect})."
        status, headers, body = Cilantro.app.call(env)
        # puts "Response ready (#{status})"

        @to_parent.puts JSON.generate([status, headers.to_hash, slurp(body)])
        @to_parent.puts @boundary
      end

      private
        def slurp(body)
          return body    if body.respond_to? :to_ary
          return [body]  if body.respond_to? :to_str

          buf = []
          body.each { |part| buf << part }
          buf
        end
      
    end # class AppProcess


    def initialize
      # puts "Reloader initialized."
      @need_to_reload = false

      @monitor = FileMonitor.new
      @monitor.add(Dir.pwd) do |i|
        @need_to_reload = true
      end
      
      child

      trap('INT') {
        stop_child
        exit! 0
      }
    end

    def child
      @child || begin
        # puts "Starting new child..."
        @from_child.close if @from_child
        @to_child.close if @to_child
        @from_child, @to_parent = IO.pipe
        @from_parent, @to_child = IO.pipe
        @boundary = String.random(30) + "\n"
        run_child unless @child = fork # child never gets out of here...
        @to_parent.close
        @from_parent.close
        # puts "New child started: #{@child.inspect}"
      end
      @child
    end

    def call(env)
      # puts "[P] Sent: " + env.inspect
      env.delete('rack.errors')
      env.delete('async.callback')
      env.delete('async.close')
      rack_input = env.delete('rack.input')
      env['rack.input'] = rack_input.readlines.join

      # Reload child if necessary here!
      new_child if app_updated?
      @need_to_reload = false

      send_to_child(env)
      reply = recv_from_child
      result = JSON.parse(reply)
      if result.length == 3
        result
      else
        [500, {'Content-Type'=>'text/html;charset=utf-8'}, [format_error(result)]]
      end
      # puts "[P] Received: " + reply.inspect
    end

    def app_updated?
      @monitor.process
      @need_to_reload
    end

    def send_to_child(msg)
      # puts "#{msg['REQUEST_METHOD']} #{msg['REQUEST_PATH']}"
      @to_child.puts JSON.generate(msg)
      @to_child.puts "\n" + @boundary
    end

    def new_child
      puts "Reloading app..."
      stop_child
      child
    end

    def stop_child
      if @child
        Process.kill('INT', @child)
        @child = nil
      end
    end

    private
    
      def run_child
        @to_child.close
        @from_child.close
        # Detach from the controlling terminal
        # Process.setsid
        # Prevent the possibility of acquiring a controlling terminal
        @stdout = $stdout
          $stdout = File.open('/dev/null', 'w')
        @stderr = $stderr
          $stderr = File.open('/dev/null', 'w')
        # trap 'SIGHUP', 'IGNORE'
        # fork and exit
        begin
          AppProcess.new(@from_parent, @to_parent, @boundary, @stdout, @stderr)
        rescue Object => err
          @to_parent.puts JSON.generate(["#{err.class.name}: #{err.to_s}", err.backtrace])
          @to_parent.puts @boundary
        ensure
          puts "PREMATURE EXIT!"
          exit! 1
        end
      end

      def recv_from_child
        # Gets the next message, separated by @boundary.
        reply = IO.slurp(@from_child, @boundary)
        return reply
      end

      def format_error(result)
        message, backtrace = result
        "<h1>500 Server Error</h1><h3>#{escape_html(message)}</h3>" +
        "<pre>#{escape_html(backtrace.join("\n"))}</pre>"
      end
  end
end
