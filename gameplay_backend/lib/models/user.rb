require_relative 'base_model'

class User
  include Dynamoid::Document

  table name: ENV.fetch('USERS_TABLE_NAME'), timestamps: false, key: :user_id

  field :status, :string
  field :entities, :array
end
