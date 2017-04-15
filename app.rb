require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'dotenv/load'

require_relative 'models/spotify_api'

def get_redirect_uri(request)
  URI.escape("#{request.base_url}/callback/spotify",
             Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_spotify_api
  SpotifyApi.new(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])
end

get '/' do
  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = get_redirect_uri(request)
  erb :index
end

get '/callback/spotify' do
  code = params['code']
  redirect_uri = get_redirect_uri(request)
  api = get_spotify_api
  token = api.get_token(code, redirect_uri)
  "token: #{token.inspect}"
end
