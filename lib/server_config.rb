class ServerConfig

  class << self
    attr_accessor :twilio_account_id
    attr_accessor :twilio_api_secret
    attr_accessor :worker_phone
    attr_accessor :user_phone
    attr_accessor :server_phone
    attr_accessor :numbers
  end

end