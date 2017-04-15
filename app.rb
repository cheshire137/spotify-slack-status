require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'dotenv/load'

def get_redirect_uri(request)
  URI.escape("#{request.base_url}/callback/spotify",
             Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_token(code, redirect_uri)
  client_id = ENV['SPOTIFY_CLIENT_ID']
  client_secret = ENV['SPOTIFY_CLIENT_SECRET']
  grant = Base64.strict_encode64("#{client_id}:#{client_secret}")

  uri = URI.parse('https://accounts.spotify.com/api/token')
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true

  header = { 'Authorization' => "Basic #{grant}" }
  req = Net::HTTP::Post.new(uri.request_uri, header)
  data = { 'grant_type' => 'authorization_code',
           'code' => code, 'redirect_uri' => redirect_uri }
  req.set_form_data(data)

  res = http.request(req)
  if res.kind_of? Net::HTTPSuccess
    json = JSON.parse(res.body)
    json['access_token']
  end
end

get '/' do
  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = get_redirect_uri(request)
  erb :index
end

get '/callback/spotify' do
  code = params['code']
  redirect_uri = get_redirect_uri(request)
  token = get_token(code, redirect_uri)
  "token: #{token.inspect}"
end
