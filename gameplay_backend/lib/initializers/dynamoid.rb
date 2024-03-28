require 'dynamoid'

Dynamoid.configure do |config|
  config.namespace = nil
  config.endpoint = 'http://localhost:8000' if ['development', 'test'].include?(ENV['ENV'])
  config.logger = ENV['DEBUG'] ? Logger.new($stdout) : nil
  config.read_capacity = 10
  config.write_capacity = 10
  config.create_table_on_save = false
end

require 'models/user'     if USERS_DDB_TABLE_NAME           = ENV['USERS_TABLE_NAME']
require 'models/receipt'  if ENTITY_RECEIPTS_DDB_TABLE_NAME = ENV['ENTITY_RECEIPTS_TABLE_NAME']
require 'models/item'     if ITEMS_DDB_TABLE_NAME           = ENV['ITEMS_TABLE_NAME']
