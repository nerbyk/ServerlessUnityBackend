
require 'config'

raise('APIGW_CLIENT is not set') unless APIGW_CLIENT

def handler(event:, context:)
  LOGGER.info 'Event received: %s' % JSON.pretty_generate(event)

  user_id = event.dig('detail', 'userId')
  connection_id = event.dig('detail', 'connectionId')
  user = User.find(user_id)

  APIGW_CLIENT.post_to_connection(
    data: JSON.generate(user.attributes),
    connection_id: event.dig('detail', 'connectionId')
  )

  { statusCode: 200, body: 'OK' }
rescue => e
  LOGGER.error(e)
  raise e
end
