require 'aws-sdk-cognitoidentityprovider'
require 'aws-cognito-srp'
require 'jwt'
require_relative 'ssm'

ENV['CDK_STACK_NAME'] ||= 'test--BusinessFarm'

module AwsSdkHelpers
  class Cognito
    Client = Aws::CognitoIdentityProvider::Client.new

    USER_POOL_ID = Ssm::Client.get_parameter(name: "/#{ENV['CDK_STACK_NAME']}/cognito/user-pool-id").parameter.value
    USER_POOL_CLIENT_ID = Ssm::Client.get_parameter(name: "/#{ENV['CDK_STACK_NAME']}/cognito/user-pool-client-id").parameter.value

    JWKS_URI = URI("https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{USER_POOL_ID}/.well-known/jwks.json")

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

    def self.sign_up_user(email:, password:, confirmed: false)
      Client.sign_up({
        client_id: USER_POOL_CLIENT_ID,
        username: email,
        password: password,
        user_attributes: [
          { name: 'email', value: email }
        ]
      }).tap { |it| confirm_user(username: it.user_sub) if confirmed }
    rescue Aws::CognitoIdentityProvider::Errors::UsernameExistsException
      delete_user(email)
      retry
    end

    def self.sign_in_user(username:, password:)
      Aws::CognitoSrp.new(
        username:,
        password:,
        pool_id: USER_POOL_ID,
        client_id: USER_POOL_CLIENT_ID,
        aws_client: Client
      ).authenticate
    end

    def self.verify_jwt_token(token)
      jwks = JSON.parse(Net::HTTP.get(JWKS_URI), symbolize_names: true)
      JWT.decode(token, nil, true, { jwks:, algorithms: ['RS256'] })
    end

    def self.confirm_user(username:)
      Client.admin_confirm_sign_up({
        user_pool_id: USER_POOL_ID,
        username: username
      })
    end
  end
end
