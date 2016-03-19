require 'pathname'
require 'log4r'

class ServerLogger
  module Constants
    LOG_SEPARATOR = ' | '
    LOG_PATTERN = %w(%d %l %m).join(LOG_SEPARATOR)
    TIME_FORMAT = '%Y-%m-%dT%H:%M:%S:%L%:z'
  end

  class << self
    attr_accessor :app, :config, :env

    def app
      @app ||= :cfi_server
    end

    def env
      @env ||= :development
    end

    def config
      @config ||= {}
    end

    def default(level, *log)
      log(app, level, *log)
    end

    def log(name, level, *log)
      logger = logger(name)
      create_outputters name unless File.writable? config[env][name]
      logger.send level, log.join(Constants::LOG_SEPARATOR)
    end

    def logger(name)
      name = app if name == :default
      @loggers ||= {}
      @loggers[name] ||= Log4r::Logger.new(name.to_s)
      @loggers[name].level = config_for(name)[:level]
      create_outputters name
      @loggers[name]
    end

    def config_for(name)
      config[env] ||= {}
      config[env][:level] ||= Log4r::ALL
      config[env][name] ||= "log/#{name.to_s}"
      config[env][name] = File.expand_path(config[env][name]) if Pathname.new(config[env][name]).relative?
      config[env]
    end

    def create_outputters(name)
      path = config[env][name]
      logger = @loggers[name]
      logger.outputters.clear
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir) unless File.directory? dir
      formatter = Log4r::PatternFormatter.new(pattern: Constants::LOG_PATTERN, date_pattern: Constants::TIME_FORMAT)
      logger.outputters << Log4r::FileOutputter.new(name, filename: path, formatter: formatter)
      logger.outputters << Log4r::StdoutOutputter.new(name, formatter: formatter) if env == :development
    end
  end
end
