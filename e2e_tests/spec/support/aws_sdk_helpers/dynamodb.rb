require 'aws-sdk-dynamodb'

module AwsSdkHelpers
  class DynamoDB
    Client = Aws::DynamoDB::Client.new

    SCHEMAS = {
      user: {
        table_name: ENV['USERS_TABLE_NAME'] || ENV.fetch('CDK_STACK_NAME') + '-Users',
        key: :user_id
      },
      connection: {
        table_name: ENV.fetch('WEBSOCKET_CONNECTIONS_TABLE_NAME'),
        key: :connectionId
      },
      connection_user_id_index: {
        table_name: ENV.fetch('WEBSOCKET_CONNECTIONS_TABLE_NAME'),
        index_name: 'userIdIndex',
        key_condition_expression: 'userId = :user_id',
        expression_attribute_values: {
          ':user_id' => nil
        },
        limit: 1
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

    def self.find_by_index(table, index_name, value)
      opts = SCHEMAS.fetch(:"#{table}_#{index_name}_index") 
      opts[:expression_attribute_values][":#{index_name}"] = value

      Client.query(opts)
    end
  end
end
