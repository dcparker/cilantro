class App
  class << self
    def live?
      APP_CONFIG[:is_live]
    end
  end
end
