require 'dynamoid'

Dynamoid.configure do |config|
  config.namespace = nil
  # config.logger = ENV['DEBUG'] ? Logger.new($stdout) : nil
  config.read_capacity = 10
  config.write_capacity = 10
end