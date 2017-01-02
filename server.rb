require 'sinatra'
require 'json'
require './page'
require 'net/http'

set :bind, '0.0.0.0'
set :port, 4020

Encoding.default_external = Encoding::UTF_8

helpers do

  def wikilinks uri
    html = Net::HTTP.get(uri)
    STDERR.puts html.inspect
    html.force_encoding('UTF-8')
    title = (/<title>(.+) - Wikipedia<\/title>/.match html)[1]
    source = {:url => uri.to_s, :transport => 'http://localhost:4020/proxy'}
    page title, source do
      paragraph "From [[Explore Transport Proxy]]. See [#{uri} wikipedia]"
      count = Hash.new(0)
      html.scan(/href="\/wiki\/([^"]+)" title="([^^"]+)"/) do |href, title|
        next unless title =~ /^[a-zA-Z ]+$/
        next unless (count[title]+=1) == 1
        paragraph "[[#{title}]]"
      end
    end
  end

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
      <p><a id=link target="_blank" href="http://localhost:3030/">begin</a></p>
      <script>
        link.href += location.host + "/transport-proxy"
      </script>
    </body>
  </html>
EOF
end

post "/proxy", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  if params['title']
    uri = URI("https://en.wikipedia.org/wiki/#{params['title'].gsub(/ /,'_')}")
  else
    uri = URI(params['text'])
  end
  wikilinks uri
end

post "/import", :provides => :json do
  params = JSON.parse(request.env["rack.input"].read)
  if params['title']
    uri = URI("https://en.wikipedia.org/wiki/#{params['title'].gsub(/ /,'_')}")
  else
    uri = URI(params['text'])
  end
  links = JSON.parse wikilinks uri
  pages = {}
  links['story'].each do |item|
    next unless item['text'] =~ /^\[/
    title = item['text'].gsub(/\[|\]/,'')
    linkuri = URI("https://en.wikipedia.org/wiki/#{title.gsub(/ /,'_')}")
    pages[slug title] = JSON.parse wikilinks linkuri
  end
  source = {:url => uri.to_s, :transport => 'http://localhost:4020/import'}
  page "#{links['title']} (import)", source do
    paragraph "Select a page linked from #{links['title']}. [#{uri} wikipedia]"
    item 'importer', :pages => pages
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
