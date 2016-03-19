module ApiServer
  class App < Padrino::Application
    register Padrino::Rendering
    register Padrino::Mailer
    register Padrino::Helpers

    set :sessions, false
    set :logging, true
    set :method_override, false
    set :static, false
    set :run, false
    set :dump_errors, development?
    set :raise_errors, false
    set :show_exceptions, false
    # set :protection, except: [:remote_referrer, :json_csrf]

    error 405 do
      ServerRequest.send_exception MethodNotAllowed.new
    end

    not_found do
      ServerRequest.send_exception @server_error || InvalidAPIPathError.new
    end

    after do
      response.headers["Access-Control-Allow-Origin"] = "*"
    end


    error do |e|
      @server_error = ServerRequest.server_error e
      ServerRequest.send_exception @server_error
    end

    class << self
      def controller(*args, &block)
        # @controllers_config ||= YAML.load_file(Padrino.root('config', 'server_config.yml'))
        # super(*args, &block) if @controllers_config[environment] && @controllers_config[environment].index(args[0])
        super(*args, &block)
      end

      alias :controllers :controller
    end


  end
end
