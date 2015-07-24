require 'cgi'
require 'em-websocket'
require 'em-hiredis'

EM.run do
  EM::WebSocket.run(host: '0.0.0.0', port: 8080) do |ws|
    ws.onopen do |handshake|
      puts "WebSocket connection open"

      ws.send "Hello Client, you connected to #{handshake.path}"

      @redis = EM::Hiredis.connect
      pubsub = @redis.pubsub
      pubsub.subscribe('main')

      pubsub.on(:message) do |channel, message|
        ws.send message
      end
    end

    ws.onclose do
      @redis.pubsub.unsubscribe('main')
      @redis.close_connection

      puts "Connection closed"
    end

    ws.onmessage do |msg|
      @redis.publish 'main', msg
    end
  end
end
