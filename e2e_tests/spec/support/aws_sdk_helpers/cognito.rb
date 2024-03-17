require 'aws-sdk-cognitoidentityprovider'
require_relative 'ssm'

module AwsSdkHelpers
  class Cognito
    Client = Aws::CognitoIdentityProvider::Client.new

    USER_POOL_ID = Ssm::Client.get_parameter(name: "/#{ENV['CDK_STACK_NAME']}/cognito/user-pool-id").parameter.value
    USER_POOL_CLIENT_ID = Ssm::Client.get_parameter(name: "/#{ENV['CDK_STACK_NAME']}/cognito/user-pool-client-id").parameter.value

    def self.get_user(username)
      Client.admin_get_user({
        user_pool_id: USER_POOL_ID,
        username: username
      })
    end

    def self.delete_user(username)
      Client.admin_delete_user({
        user_pool_id: USER_POOL_ID,
        username: username
      })
    end

    def self.singup_user(email:, password:, code: nil)
      Client.sign_up({
        client_id: USER_POOL_CLIENT_ID,
        username: email,
        password: password,
        user_attributes: [
          { name: 'email', value: email }
        ],
        validation_data: code.nil? ? [] : [{ name: 'confirmationCode', value: code }]
      })
    rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
      delete_user(email)
      retry
    end

    def self.confirm_user(username:, code: nil)
      if code.nil?
        Client.admin_confirm_sign_up({
          user_pool_id: USER_POOL_ID,
          username: username
        })
      else
        Client.confirm_sign_up({
          client_id: USER_POOL_CLIENT_ID,
          username: username,
          confirmation_code: code
        })
      end
    end
  end
end
