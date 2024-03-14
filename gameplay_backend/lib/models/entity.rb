require_relative 'base_model'

class Entity
  include Dynamoid::Document

  table name: ENV.fetch('ENTITIES_TABLE_NAME'), key: :guid

  field :etype, :string
  field :position_x, :set, of: :integer
  field :position_y, :set, of: :integer
  field :receipt_ids, :set, of: :string

  range :user_id, :string
  global_secondary_index hash_key: :user_id, name: "user_id-index"
end
