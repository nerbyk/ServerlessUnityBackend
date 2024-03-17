# frozen_string_literal: true

require 'bundler/setup'

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'minitest/reporters'

require 'dotenv'

Dotenv.load('.env.test')

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]
