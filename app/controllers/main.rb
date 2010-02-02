class Main < Application
  namespace '/'

  get :home do
    template :index
  end

  # Main page
  get 'new_index' do
    template :index
  end

  get 'auth_spec' do
    template :auth_spec
  end

  get 'paypal_receipt' do
    @transaction_id = params[:tx]

    pdt = Paypal::PDT.get(@transaction_id)
    if pdt.success
      if pdt.payment_status == 'Completed'
        msg = "Thank you for your payment. Your transaction has been completed, and a receipt for your purchase has been emailed to you. You may log into your account at www.paypal.com/us to view details of this transaction."
        # Save the details of the transaction, or at least .. email them?
        gmail = Gmail.new(GMAIL_USERNAME, GMAIL_PASSWORD)
        eml = gmail.new_message
        eml.content = template(:payment_email,
          :first_name => pdt.first_name,
          :last_name => pdt.last_name,
          :email => pdt.payer_email,
          :purchase => pdt.option_selection1,
          :deliver_to => pdt.option_selection2,
          :payment_amount => pdt.payment_gross,
          :payment_status => pdt.payment_status
        ).to_s
        eml.to pdt.last_name
        gmail.send_email(eml)
        template :paypal_receipt
        template.msg = "Thank you for your payment. Your transaction has been completed, and a receipt for your purchase has been emailed to you. You may log into your account at www.paypal.com/us to view details of this transaction."
      else
        raise "Error - Payment not Completed!"
      end
    else
      raise "PDT Error!"
    end
  end

  get 'licenses/:domain' do |domain|
    license = YAML.load_file("config/licenses/#{domain}.license")
    private_key = File.read("config/licenses/#{domain}.key")

    domain = license[:domain]
    site_key = license[:site_key]
    session[:id] ||= (1..40).collect { (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }.join

    private_key = OpenSSL::PKey::RSA.new(private_key)

    enc_string = "#{domain.split(':')[0]}@#{session[:id]}@#{site_key}"
    enc = []
    token_b = ''
    (enc_string.length.to_f / 117).ceil.times do |i|
      token_b = token_b + private_key.private_encrypt( enc_string[i*117,117] )
    end
    token = CGI.escape( Base64.encode64( token_b ).gsub(/\n/,'') )
    # puts "Token: #{token}"
    content_type 'text/javascript'
    json = {:domain => CGI.escape( domain ), :token => token}.to_json
    "#{params[:callback]}(#{json})"
  end

  # This is not yet limited to just one controller or namespace.
  error do
    Cilantro.report_error(env['sinatra.error'])
    template :default_error_page
  end
end
