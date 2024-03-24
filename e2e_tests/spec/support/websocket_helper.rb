require 'websocket-client-simple'
require 'json'
require 'delegate'

class WebSocketHelper
  WS_URL = ENV.fetch('WEBSOCKET_URL')

  attr_reader :queue

  def initialize
    @queue = Queue.new
    @ws = nil
  end

  def connect(jwt_token)
    build_ws_client(jwt_token)
  end

  def build_ws_client(token)
    WebSocket::Client::Simple.connect(WS_URL, {
      headers: { 'Authorization' => "Bearer #{token}"}
    }) do |ws|
      ws.on :message do |msg|
        @queue << JSON.parse(msg.data)
      end

      ws.on :error do |err| 
        @queue << { error: err.full_message }
      end
    end.tap { |it| it.instance_variable_set(:@queue, @queue) }
  end
end
