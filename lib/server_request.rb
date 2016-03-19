require 'server_exceptions'
require 'server_logger'
require 'middleware/server_request_info'

class ServerRequest
  def initialize(app)
    @app = app
  end

  def call(env)
    begin
      self.process_env(env)
      status, headers, body = @app.call env
      sym = :info
    rescue Exception => e
      status, headers, body = ServerRequest.send_exception e
      headers['X-Response-Code'] = ServerRequestInfo.http_error_code.to_s if ServerRequestInfo.http_error_code
      sym = :error
    ensure
      ServerRequestInfo.reset
    end
    [status, headers, body]
  end

  def process_env(env)
    ServerRequestInfo.http_method = env['REQUEST_METHOD']
    ServerRequestInfo.http_path = env['REQUEST_PATH']
    ServerRequestInfo.http_user_agent = env['HTTP_USER_AGENT'] || ''
    ServerRequestInfo.http_user_ip = env['REMOTE_ADDR']
  end

  class << self
    def server_error(e)
      e = DatabaseConnectionError.new(e) if e.kind_of?(Sequel::DatabaseError)
      e = UnknownInternalError.new(e) unless e.kind_of?(ServerException)
      e
    end

    def send_exception(e)
      e = server_error e
      body = e.to_json
      ServerLogger.default :error, 'server', "#{ServerRequestInfo.http_method} #{ServerRequestInfo.http_path} HTTP/#{e.http_code}: code #{e.error_code}", *e.trace rescue nil if e.http_code >= 500
      ServerRequestInfo.http_error_code = e.error_code
      [e.http_code, self.headers(body), body]
    end

    def headers(body)
      {
          'Content-Type' => 'application/json',
          'Content-Length' => body.size.to_s
      }
    end
  end
end
