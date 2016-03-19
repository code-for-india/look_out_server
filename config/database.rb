Sequel::Model.raise_on_save_failure = true
Sequel::Model.plugin :timestamps, :update_on_create=>true

config = YAML.load_file(Padrino.root('config', 'database.yml'))
DB = Sequel.connect(config[Padrino.env])
DB.sql_log_level = :debug
DB.loggers << logger
Sequel::Model.db.extension(:pagination)