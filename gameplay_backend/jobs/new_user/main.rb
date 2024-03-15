require 'logger'
require 'securerandom'
require 'aws-sdk-s3'

require 'models/user'

STATICS_S3_BUCKET_NAME = ENV.fetch('STATICS_S3_BUCKET_NAME')
S3_CLIENT = Aws::S3::Client.new

DEFAULT_ENTITY_MAPPING_OPTIONS = {
  bucket: STATICS_S3_BUCKET_NAME,
  key: "default_entity_map.json"
}.freeze

DEFAULT_ITEMS_MAPPING_OPTIONS = {
  bucket: STATICS_S3_BUCKET_NAME,
  key: "default_items_map.json"
}.freeze

DEFAULT_ENTITY_MAPPING = JSON.parse(
  S3_CLIENT.get_object(DEFAULT_ENTITY_MAPPING_OPTIONS).body.read,
  symbolize_names: true
).freeze

DEFAULT_ITEMS_MAPPING = JSON.parse(
  S3_CLIENT.get_object(DEFAULT_ITEMS_MAPPING_OPTIONS).body.read,
  symbolize_names: true
).freeze 

ENTITY_MAP_SIZE = 100
LOGGER = Logger.new($stdout).freeze

def handler(event:, context:)
  LOGGER.info "Event received: %s" % JSON.pretty_generate(event)

  user_id = JSON.parse(event['detail']).dig('userName')
  entities_map = Array.new(ENTITY_MAP_SIZE) { Array.new(ENTITY_MAP_SIZE) { { type: nil, guid: nil } } }

  DEFAULT_ENTITY_MAPPING.each do |entity|
    guid = SecureRandom.uuid
  
    entity[:x].each do |x|
      entity[:y].each do |y|
        entities_map[x - 1][y - 1][:type] = entity[:type]
        entities_map[x - 1][y - 1][:guid] = guid
      end
    end
  end

  User.create(user_id: user_id, entities: entities_map ) unless User.exists?(user_id: user_id)

  { statusCode: 200, body: "OK" }
rescue StandardError => e
  User.find(user_id).delete if respond_to?(:user_id)

  raise e
end
