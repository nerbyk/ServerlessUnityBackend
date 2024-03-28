
require 'config'

def handler(event:, context:)
  LOGGER.info 'Event received: %s' % JSON.pretty_generate(event)

  user_id = event.dig('requestContext', 'authorizer', 'customerId')
  user = User.find(user_id)

  { 
    statusCode: 200, 
    body: { 
      user_id: user.user_id, 
      entites: user.entities 
    }.to_json,
    headers: {'Content-Type': 'application/json'}
  }
rescue => e
  LOGGER.error(e)
  raise e
end
