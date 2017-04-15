require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'sinatra/activerecord'
require 'dotenv/load'

require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'
require_relative 'models/user'

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_spotify_auth_api
  SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'], ENV['SPOTIFY_CLIENT_SECRET'])
end

not_found do
  status 404
  erb :not_found
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
  tokens = auth_api.get_tokens(code, redirect_uri)

  if tokens
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    api = SpotifyApi.new(access_token)

    if me = api.get_me
      user = User.where(email: me['email']).first_or_initialize
      user.spotify_access_token = access_token
      user.spotify_refresh_token = refresh_token

      if user.save
        "Signed in as #{user.email}"
      else
        "Failed to sign in: #{user.errors.full_messages.join(', ')}"
      end
    end
  else
    "Failed to authenticate with Spotify"
  end
end
