if (STATICS_S3_BUCKET_NAME = ENV['STATICS_S3_BUCKET_NAME'])
  require 'aws-sdk-s3'

  S3_CLIENT = Aws::S3::Client.new
end

if (EVENT_BUS_NAME = ENV['EVENT_BUS_NAME'])
  require 'aws-sdk-eventbridge'

  EVENT_BRIDGE_CLIENT = Aws::EventBridge::Client.new
end

if (APIGW_ENDPOINT = ENV['APIGW_ENDPOINT'])
  require 'aws-sdk-apigatewaymanagementapi'

  APIGW_CLIENT = Aws::ApiGatewayManagementApi::Client.new(endpoint: APIGW_ENDPOINT)
end