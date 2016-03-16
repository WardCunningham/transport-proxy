require 'sinatra'
require 'json'
require './page'
require 'net/http'

set :bind, '0.0.0.0'
set :port, 4020

Encoding.default_external = Encoding::UTF_8

helpers do
end

before do
  response['Access-Control-Allow-Origin'] = '*'
end

# https://www.snip2code.com/Snippet/85077/Sinatra-with-cross-origin-AJAX-requests-
options '*' do
  headers 'Access-Control-Allow-Headers' => 'Accept, Authorization, Content-Type',
          'Access-Control-Allow-Methods' => 'GET, POST, PUT, PATCH, DELETE OPTIONS, LINK, UNLINK',
          'Access-Control-Max-Age'       => '600'
end


get '/' do
<<EOF
  <html>
    <head>
      <link id='favicon' href='/favicon.png' rel='icon' type='image/png'>
    </head>
    <body style="padding:40px; text-align:center;">
      <h1>Transport Proxy</h1>
      <p><a id=link target="_blank" href="http://ward.asia.wiki.org/">details</a></p>
      <script>
        link.href += location.host + "/transport-proxy"
      </script>
    </body>
  </html>
EOF
end

post "/proxy", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  uri = URI(params['text'])
  html = Net::HTTP.get(uri)
  html.force_encoding('UTF-8')
  title = (/<title>(.+) - Wikipedia, the free encyclopedia<\/title>/.match html)[1]
  page title do
    paragraph "From [[Explore Transport Proxy]]. See [#{params['text']} wikipedia]"
    html.scan(/href="\/wiki\/([^"]+)" title="([^^"]+)"/) do |href, title|
      paragraph "[[#{title}]]"
    end
  end
end

get '/system/sitemap.json' do
  send_file 'status/sitemap.json'
end

get '/favicon.png' do
  send_file 'status/favicon.png'
end

get %r{^/([a-z0-9-]+)\.json$} do |slug|
  send_file "pages/#{slug}"
end

get %r{^/view/} do
  redirect '/'
end
