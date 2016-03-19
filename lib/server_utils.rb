require 'json'
require 'base64'
require 'net/http'
require 'twilio-ruby'
require 'server_config'

class ServerUtils

  class << self
    def get_lat_lng(address)
      return nil if address.nil?
      url = 'https://maps.googleapis.com/maps/api/geocode/json?address=' + address
      url = URI::encode(url)
      uri = URI(url)
      response = Net::HTTP.get(uri)
      body = JSON.parse(response)
      return nil unless body.include? 'results'
      results = body['results']
      return nil unless results.length >= 1
      location = results[0]['geometry']['location']
      return location['lat'], location['lng']
    end

    def get_address(lat, lng)
      url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=' + lat.to_s + ','+lng.to_s
      url = URI::encode(url)
      uri = URI(url)
      response = Net::HTTP.get(uri)
      body = JSON.parse(response)
      return nil unless body.include? 'results'
      results = body['results']
      return nil unless results.length >= 1
      address = results[0]['formatted_address']
      return address
    end


    def send_sms(phone, msg)
      # put your own credentials here
      account_sid = ServerConfig.twilio_account_id
      auth_token = ServerConfig.twilio_api_secret

      # set up a client to talk to the Twilio REST API
      @client = Twilio::REST::Client.new account_sid, auth_token
      from = ServerConfig.server_phone
      @msg_id =	UUIDTools::UUID.random_create.hexdigest
      @client.account.messages.create({
                                          :from => from,
                                          :to => phone,
                                          :body => msg
                                      })
    end

    def get_loo_contact(loo_id)
      index = loo_id.to_i % 100
      if ServerConfig.numbers.nil?
        ServerConfig.numbers= []
        100.times do
          random_phone= "+91 99" + rand.to_s[2..9]
          ServerConfig.numbers << random_phone
        end
      end
      return ServerConfig.numbers[index.to_i]
    end
  end






end
