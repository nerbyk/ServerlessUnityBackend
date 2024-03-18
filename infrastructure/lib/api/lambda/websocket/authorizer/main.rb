require 'jwt'
require 'net/http'
require 'json'
require 'logger'

COGNITO_USER_POOL_ID = ENV.fetch('COGNITO_USER_POOL_ID')
JWKS_URI = URI("https://cognito-idp.#{ENV['AWS_REGION']}.amazonaws.com/#{COGNITO_USER_POOL_ID}/.well-known/jwks.json")
Log = Logger.new($stdout)

def generate_policy(principal_id:, effect:, resource:)
  {
    principalId: principal_id,
    policyDocument: {
      Version: '2012-10-17',
      Statement:[
        {
          Action: 'execute-api:Invoke',
          Effect: effect,
          Resource: resource
        }
      ]
    },
    context: {
      customerId: principal_id
    }
  }
end

def handler(event:, context:)
  Log.info(event)

  token = event['headers']['Authorization'].gsub('Bearer ', '')
  jwks = JSON.parse(Net::HTTP.get(JWKS_URI), symbolize_names: true)
  decoded_token = JWT.decode(token, nil, true, { algorithms: ['RS256'], jwks: })

  generate_policy(
    principal_id: decoded_token[0]['sub'],
    effect: 'Allow',
    resource: event['methodArn']
  ).tap { |it| Log.info(it) }
rescue => e
  Log.error(e)
  generate_policy(
    principal_id: 'default',
    effect: 'Deny',
    resource: event['methodArn']
  )
end

