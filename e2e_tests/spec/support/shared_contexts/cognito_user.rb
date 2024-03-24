require 'support/aws_sdk_helpers/cognito'
require 'support/aws_sdk_helpers/dynamodb'

TEST_USER = {
  :email => "e2e_test_user@email.com", 
  :password => "password",
}

RSpec.shared_context :cognito_user do
  before(:all) do
    @user = begin
      AwsSdkHelpers::Cognito.sign_in_user(username: TEST_USER[:email], password: TEST_USER[:password])
    rescue Aws::CognitoIdentityProvider::Errors::UserNotFoundException
      AwsSdkHelpers::Cognito.sign_up_user(**TEST_USER, confirmed: true)
    
      retry
    end
  end
end
