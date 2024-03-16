require 'spec_helper'
require 'support/aws_sdk_helpers/dynamodb'
require 'support/aws_sdk_helpers/cognito'

describe 'User Registration' do
  let(:user_email) { 'test_user@example.com' }
  let(:user_password) { '12345678' }
  
  after do 
    AwsSdkHelpers::Cognito.delete_user(user_email)
  end
    
  context "when new user confirms their email" do
    let!(:user) { AwsSdkHelpers::Cognito.singup_user(email: user_email, password: user_password) }

    def db_user = AwsSdkHelpers::DynamoDB.find(:user, by: user.user_sub).item

    after { AwsSdkHelpers::DynamoDB.delete(:user, user.user_sub)}

    it "should create new user in dynamodb" do
      expect(db_user).to be_nil

      AwsSdkHelpers::Cognito.confirm_user(username: user_email)

      sleep(5)

      expect(db_user).to_not be_nil
    end
  end
end