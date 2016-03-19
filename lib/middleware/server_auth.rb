require 'middleware/server_request'
# require 'token_validator'
require 'server_exceptions'

class ServerAuth
  module Constants
    PATH_RULES = {
        /^\/v1\/version$/ => lambda { |*args| },
    }
  end

  def initialize(app)
    @app = app
  end

  def call(env)
    self.validate_access env
    @app.call env
  end

  def validate_access(env)
    path = ServerRequestInfo.http_path
    Constants::PATH_RULES.each do |regex, proc|
      if regex =~ path
        proc.call self, env
        break
      end
    end
  end
end
