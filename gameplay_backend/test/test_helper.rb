require "bundler/setup"
require "minitest/autorun"
require "minitest/reporters"
require "dotenv"

Dotenv.load(".env.test")

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

