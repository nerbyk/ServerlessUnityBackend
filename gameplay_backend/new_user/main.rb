require 'logger'

LOGGER = Logger.new($stdout)

def handler(event:, context:)
  LOGGER.info(event)
end
