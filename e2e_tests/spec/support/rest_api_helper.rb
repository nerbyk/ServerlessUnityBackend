require 'net/http'
require 'json'
require 'delegate'

class RestApiHelper
  API_URL = ENV.fetch('REST_API_URL')

  DEFAULT_HEADERS = {
    "Accept" => "application/json; charset=utf-8"
  }.freeze

  def self.get(path, jwt_token)
    make_request(
      Net::HTTP::Get.new(compose_uri(path), { 'Authorization' => "Bearer #{jwt_token}" })
    )
  end

  private

  def self.make_request(req)
    Net::HTTP.new(req.uri.host, req.uri.port).tap do |http|
      http.use_ssl = true
    end.request(req)
  end

  def self.compose_uri(path)
    URI("#{API_URL}#{path}")
  end
end
