require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'dotenv/load'

require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_spotify_auth_api
  SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])
end

get '/' do
  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/spotify")
  erb :index
end

get '/callback/spotify' do
  code = params['code']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")

  auth_api = get_spotify_auth_api
  token = auth_api.get_token(code, redirect_uri)

  if token
    api = SpotifyApi.new(token)

    currently_playing = api.get_currently_playing

    "Current track: #{currently_playing}"
  else
    "Failed to authenticate"
  end
end
