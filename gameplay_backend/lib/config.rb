# frozen_string_literal: true

unless ENV['AWS_LAMBDA_FUNCTION_NAME']
  require 'dotenv'
  Dotenv.load(".env.#{ENV['ENV']}")
end

require 'initializers/dynamoid'
require 'initializers/aws_sdk'

LOGGER = Logger.new($stdout).freeze
