
require 'config'

def handler(event:, context:)
  LOGGER.info 'Event received: %s' % JSON.pretty_generate(event)

  user_id = event.dig('detail', 'userId')
  connection_id = event.dig('detail', 'connectionId')
 
  user = User.find(user_id)
  user_items = Item.where(user_id: user_id)

  { 
    statusCode: 200, 
    body: { 
      user_id: user.user_id, 
      items: user_items.map { |item| item.attributes }, 
      entites: user.entities 
    } 
  }
rescue => e
  LOGGER.error(e)
  raise e
end
