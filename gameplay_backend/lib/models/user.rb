# frozen_string_literal: true

class User
  include Dynamoid::Document

  table name: USERS_DDB_TABLE_NAME, timestamps: false, key: :user_id

  field :status, :string
  field :entities, :map
end
