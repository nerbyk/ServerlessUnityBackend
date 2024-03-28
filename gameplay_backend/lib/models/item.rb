# frozen_string_literal: true

class Item
  include Dynamoid::Document

  table name: ITEMS_DDB_TABLE_NAME, timestamps: false, key: :guid

  field :amount, :integer, default: 0
  field :etype, :string

  range :user_id, :string
end
