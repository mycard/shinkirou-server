http = require("http")
url  = require("url")
_    = require("underscore")
settings = require("./config")
dgram = require('dgram');

host_ip = null
client_ip = null
client_connections = {}
host_port = {}
client_connections_count = 2

waiting = null

# http
httpserver = http.createServer (request, response)->
  console.log "#{new Date()} Received request for #{request.url} from #{request.connection.remoteAddress})"
  if url.parse(request.url).pathname != '/'
    response.writeHead(404);
    response.end();
    return

  waiting = response
  response.writeHead(200, {"Content-Type": "application/json"})

.listen(settings.http_port)

#udp

udpserver = dgram.createSocket('udp4');

udpserver.on 'listening', ->
  address = udpserver.address();
  console.log('UDP Server listening on ' + address.address + ":" + address.port);

udpserver.on 'message', (message, remote)->
  if remote.address == host_ip and _.size(client_connections) == client_connections_count and !client_connections[remote.port]
    #port = _.keys(client_connections)[0]
    #console.log "1: #{remote.address}:#{remote.port} -> #{client_ip}:#{port} #{message.length} ", message
    #udpserver.send(message, 0, message.length, port, client_ip)
    console.log "dropped #{remote.address}:#{remote.port} #{message.length} ", message
  else
    client_ip = remote.address
    if !client_connections[remote.port]
      console.log "new udp connection from #{remote.address}:#{remote.port}"
      client = dgram.createSocket('udp4');
      client_connections[remote.port] = client
      client.on 'message', (response_message, response_remote)->
        host_ip = response_remote.address
        if host_port[remote.port]
          console.log "2: #{response_remote.address}:#{response_remote.port} -> #{remote.address}:#{remote.port} #{message.length} ", response_message
          udpserver.send(response_message, 0, response_message.length, remote.port, remote.address)
        else
          console.log "response udp connection from #{response_remote.address}:#{response_remote.port}"
          host_port[remote.port] = response_remote.port

      client.bind ->
        if _.size(client_connections) == client_connections_count
          waiting.end JSON.stringify (connection.address().port for connection in _.values(client_connections))

    if host_ip
      console.log "3: #{remote.address}:#{remote.port} -> #{host_ip}:#{host_port[remote.port]} #{message.length} ", message
      client_connections[remote.port].send(message, 0, message.length, host_port[remote.port], host_ip)

udpserver.bind(settings.udp_port);