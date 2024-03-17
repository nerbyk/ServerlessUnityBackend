require 'aws-sdk-ssm'

module AwsSdkHelpers
  class Ssm
    Client = Aws::SSM::Client.new
  end
end
