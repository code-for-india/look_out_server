class ServerException < StandardError
  module Constants
    UNKNOWN_ERROR = 1000
  end

  attr_reader :http_code, :error_code, :detail

  def initialize(http_code, error_code, message, *args)
    @http_code = http_code.to_i
    @http_code = 500 unless (100..599).include?(http_code)
    @error_code = error_code.respond_to?(:to_i) ? error_code.to_i : UNKNOWN_ERROR
    @error_msg = (message || 'Internal error').to_s

    @detail = {}
    args.each { |arg|
      if arg.kind_of?(Exception)
        @detail.merge({message: arg.message})
      elsif arg.kind_of?(Hash)
        @detail = arg
      end
    }
    super message
  end

  def message
    @error_msg
  end

  def to_h
    hash = {
        code: self.error_code,
        message: self.message
    }
    hash[:detail] = @detail
    hash
  end

  def to_json
    self.to_h.to_json(JSON::State.new(indent: "\t", object_nl: "\n", array_nl: "\n"))
  end

end

class UnknownInternalError < ServerException
  def initialize(e = nil)
    super 500, 1000, 'Internal server error', e
  end
end

class DatabaseConnectionError < ServerException
  def initialize(e = nil)
    super 500, 1001, 'Database communication error', e
  end
end

# Duplicated in /404.json
class InvalidAPIPathError < ServerException
  def initialize(detail = {})
    super 404, 1004, 'Invalid API Path', detail
  end
end

class InputValidationError < ServerException
  def initialize(detail = {})
    super 400, 1200, 'Input validation error', detail
  end
end

class ResourceExistsError < ServerException
  def initialize(detail = {})
    super 400, 1201, 'Resource already exists', detail
  end
end

class ResourceNotExistsError < ServerException
  def initialize(detail = {})
    super 404, 1202, 'Resource does not exist', detail
  end
end

class AccessDeniedError < ServerException
  def initialize(detail = {})
    super 403, 1203, 'Access denied', detail
  end
end

class InvalidContentTypeError < ServerException
  def initialize(detail = {})
    super 415, 1204, 'Invalid Content-Type', detail
  end
end

class MethodNotAllowed < ServerException
  def initialize(detail = {})
    super 405, 1207, 'Method not allowed', detail
  end
end



