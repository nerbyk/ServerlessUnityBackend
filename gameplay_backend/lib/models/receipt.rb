# frozen_string_literal: true

class Receipt
  include Dynamoid::Document

  table name: ENV.fetch('ENTITY_RECEIPTS_TABLE_NAME'), key: :guid

  field :type, :string
  field :state, :string

  range :entity_guid, :string
end
