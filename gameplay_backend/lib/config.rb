require 'dynamoid'

Dynamoid.configure do |config|
  config.namespace = nil
  # config.endpoint = 'http://localhost:8000' if ['development', 'test', nil].include?(ENV['env'])
  config.logger = ENV['DEBUG'] ? Logger.new($stdout) : nil
  config.read_capacity = 10
  config.write_capacity = 10
  config.create_table_on_save = false
end