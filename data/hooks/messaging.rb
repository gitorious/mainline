require 'rubygems'
require 'stomp'
require 'json'
require 'grit'

print "=> Syncing Gitorious... "


class Publisher
  def connect
    @connection = Stomp::Connection.open(nil, nil, 'localhost', 61613, true)
#    @connection.subscribe '/queue/foo', {:ack => 'auto'}
    @connected = true
  end

  def post_message(message)
    connect unless @connected
    @connection.send '/queue/GitoriousPushEvent', message, {'persistent' => true}
  end
end