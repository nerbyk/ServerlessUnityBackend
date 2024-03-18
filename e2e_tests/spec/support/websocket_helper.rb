require 'faye/websocket'
require 'json'

class WebSocketHelper
  WS_URL = ENV.fetch('WEBSOCKET_URL')

  attr_reader :queue

  def initialize
    @queue = Array.new
  end

  def connect(jwt_token)
    ws = Faye::WebSocket::Client.new(WS_URL, [], {
      headers: { 'Authorization' => "Bearer #{jwt_token}"}
    }) 
  
    ws.on :connect do 
      ws.send({action: "$connect"}.to_json)
    end

    ws.on :message do |event|
      @queue.push(event)
    end

    ws
  end
end
