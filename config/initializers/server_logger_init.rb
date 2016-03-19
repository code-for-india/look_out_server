require 'yaml'
require 'server_logger'

YAML.load_file(Padrino.root('config', 'padrino_logger.yml')).each { |env, config|
  Padrino::Logger::Config[env] = config
}

ServerLogger.config = YAML.load_file(Padrino.root('config', 'server_logger.yml'))
ServerLogger.env = Padrino.env
