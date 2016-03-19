class ServerRequestInfo
  class << self

    attr_accessor :http_method, :http_path, :http_user_agent, :http_user_ip, :http_error_code, :http_expires_at
    
    def reset
      ServerRequestInfo.http_method = nil
      ServerRequestInfo.http_path = nil
      ServerRequestInfo.http_user_agent = nil
      ServerRequestInfo.http_user_ip = nil
      ServerRequestInfo.http_expires_at = nil
      ServerRequestInfo.http_error_code = nil

    end
  end
end
