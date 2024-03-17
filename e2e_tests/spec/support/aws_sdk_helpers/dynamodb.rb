require 'aws-sdk-dynamodb'

module AwsSdkHelpers
  class DynamoDB
    Client = Aws::DynamoDB::Client.new

    SCHEMAS = {
      user: {
        table_name: ENV['USERS_TABLE_NAME'] || ENV.fetch('CDK_STACK_NAME') + '-Users',
        key: :user_id
      }
    }


    def self.delete(table, pk_value)
      SCHEMAS.fetch(table) => { table_name:, key: }
      
      Client.delete_item(table_name:, key: { key => pk_value })
    end

    def self.find(table, by:)
      SCHEMAS.fetch(table) => { table_name:, key: }
      
      Client.get_item(table_name:, key: { key => by })
    end
  end
end
