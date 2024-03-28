# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'
Dotenv.load('.env.test')

require 'minitest'
require 'minitest/autorun'
require 'minitest/rg'
require 'minitest/hooks/default'
require 'minitest/reporters'

Minitest::Reporters.use! [Minitest::Reporters::SpecReporter.new(color: true)]

Minitest::Spec.class_eval do
  require 'initializers/dynamoid'

  before do
    Dynamoid.adapter.list_tables.each do |table|
      Dynamoid.adapter.delete_table(table) if table =~ /^#{Dynamoid::Config.namespace}/
    end

    Dynamoid.adapter.tables.clear
    Dynamoid.included_models.each { |m| m.create_table(sync: true) }
  end
end
