gem 'uuidtools'
gem 'json'
gem 'json-schema'
require 'server_exceptions'

class ServerValidators
  module Constants
    CONTENT_TYPE_JSON = /^application\/json($|;?.*$)/.freeze
    UUID = /^[a-f0-9]{32}$/
  end

  class << self
    def validate_content_type(content_type, regex)
      raise InvalidContentTypeError, { content_type: 'should be valid' } unless regex =~ content_type
    end

    def validate_json_schema(key, schema, data)
      begin
        JSON::Validator.validate! schema, data, version: :draft3
      rescue JSON::Schema::ValidationError => e
        raise InputValidationError, { key => 'should be valid' }
      end
    end

    def validate_guid(keys)
      errors = {}
      keys.each { |key, value|
        begin
          raise ArgumentError unless Constants::UUID =~ value
        rescue ArgumentError
          errors[key] = 'should be a valid guid'
        end
      }
      raise InputValidationError, errors unless errors.empty?
    end

    def validate_json_string(key, data)
      parsed = nil
      begin
        parsed = JSON.parse(data)
      rescue Exception => e
        raise InputValidationError, { key => 'should be a valid json string' }
      end
      parsed
    end

    def validate_datetime(key, value)
      DateTime.iso8601(value.to_datetime.new_offset(0).to_s) rescue (raise InputValidationError, { key => 'must be valid iso8601 time' })
    end

    def is_valid_value(valid_values, value, name)
      is_valid = valid_values.include?(value)
      raise InputValidationError, { name => "must be either of #{valid_values}" } unless is_valid
      value
    end

    def validate_email(email)
      raise InputValidationError, {email: "must be valid"} unless email =~ /^\b[A-Z0-9._%a-z\-\+]+@(?:[A-Z0-9a-z\-]+\.)+[A-Za-z]{2,4}\z$/
      email
    end
  end
end
