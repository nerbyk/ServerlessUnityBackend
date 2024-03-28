require 'securerandom'
require 'config'

raise 'STATICS_S3_BUCKET_NAME is not set' unless STATICS_S3_BUCKET_NAME

DEFAULT_ENTITY_MAPPING_OPTIONS = {
  bucket: STATICS_S3_BUCKET_NAME,
  key: 'default_entity_map.json'
}.freeze

DEFAULT_ITEMS_MAPPING_OPTIONS = {
  bucket: STATICS_S3_BUCKET_NAME,
  key: 'default_items_map.json'
}.freeze

DEFAULT_ENTITY_MAPPING = JSON.parse(
  S3_CLIENT.get_object(DEFAULT_ENTITY_MAPPING_OPTIONS).body.read,
  symbolize_names: true
).freeze

DEFAULT_ITEMS_MAPPING = JSON.parse(
  S3_CLIENT.get_object(DEFAULT_ITEMS_MAPPING_OPTIONS).body.read,
  symbolize_names: true
).freeze

ENTITY_MAP_SIZE = 101

def build_entities_default_tilemap
  entities = {}

  DEFAULT_ENTITY_MAPPING.each do |entity|
    guid = SecureRandom.uuid

    entities[guid] = {
      type: entity[:type],
      position: {
        x: entity[:x],
        y: entity[:y]
      }
    }
  end

  entities
end

def handler(event:, context:)
  LOGGER.info 'Event received: %s' % JSON.pretty_generate(event)

  user_id = event.dig('detail', 'userName')
  entities = build_entities_default_tilemap

  User.create(user_id:, entities:).tap { |u| LOGGER.info 'User created: %s' % u.inspect }

  { statusCode: 200, body: 'OK' }
rescue => e
  User.find(user_id).delete if respond_to?(:user_id)

  raise e
end
