#!/bin/bash -ex

apt-get update && \
sudo apt-get -y install ruby-mongo ruby-sinatra && \

local_ipv4=$(curl http://169.254.169.254/latest/meta-data/local-ipv4)

cat > /home/ubuntu/app.rb <<EOF
require 'mongo'
require 'sinatra'

set :port, 8080
set :bind, '0.0.0.0'

configure do
  #client = Mongo::Connection.new "${mongo_address}"
  #db = client['example_data']
  client = Mongo::Client.new([ '${mongo_address}:27017' ], :database => 'example_data')
  db = client.database
  set :mongo_db, db['restaurants']
end

get '/test.htm' do
<<-PAGE
  <html>
    <head>
      <title>Nice Job!</title>
    </head>
    <body>
      <h1>
        It Works!
      </h1>
      <p>You are able to access this app over a standard HTTP connection.  Now try the database query <a href='/query.json'>endpoint</a></p>
      <p>Refresh the page to see the ASG round robin.. ip: $${local_ipv4}</p>
    </body>
  </html>
PAGE
end

get '/query.json' do
  "{record_count: #{settings.mongo_db.count}}"
end

EOF

( sleep 30 ; nohup ruby /home/ubuntu/app.rb ) &

exit 0
