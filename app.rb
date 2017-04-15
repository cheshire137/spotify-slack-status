require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'sinatra/activerecord'
require 'dotenv/load'

require_relative 'models/slack_auth_api'
require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'
require_relative 'models/user'

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

enable :sessions
set :session_secret, ENV['SESSION_SECRET']

not_found do
  status 404
  erb :not_found
end

get '/' do
  if user_id = session[:user_id]
    user = User.where(id: user_id).first

    if user
      redirect "/auth/spotify/#{user.to_param}"
      return
    end
  end

  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/spotify")
  erb :index
end

get '/auth/spotify/:id-:user_name' do
  @user = User.where(id: params['id'], user_name: params['user_name']).first
  @client_id = ENV['SLACK_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/slack")

  if @user
    erb :spotify_signed_in
  else
    status 404
    erb :not_found
  end
end

get '/callback/slack' do
  code = params['code']
  redirect_uri = "#{request.base_url}/callback/slack"

  auth_api = SlackAuthApi.new(ENV['SLACK_CLIENT_ID'],
                              ENV['SLACK_CLIENT_SECRET'])
  token = auth_api.get_token(code, redirect_uri)

  if token
    "Signed in with token: #{token}"
  else
    status 401
    "Failed to authenticate with Slack."
  end
end

get '/callback/spotify' do
  code = params['code']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")

  auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = auth_api.get_tokens(code, redirect_uri)

  if tokens
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    api = SpotifyApi.new(access_token)

    if me = api.get_me
      user = User.where(email: me['email']).first_or_initialize
      user.spotify_access_token = access_token
      user.spotify_refresh_token = refresh_token
      user.user_name = SpotifyApi.get_user_name(me['external_urls']['spotify'])

      if user.save
        session[:user_id] = user.id
        redirect "/auth/spotify/#{user.to_param}"
      else
        status 422
        "Failed to sign in: #{user.errors.full_messages.join(', ')}"
      end
    else
      status 400
      "Failed to load Spotify profile info."
    end
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end
