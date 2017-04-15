require 'base64'
require 'json'
require 'net/http'
require 'uri'
require 'sinatra'
require 'sinatra/activerecord'
require 'dotenv/load'

require_relative 'models/slack_auth_api'
require_relative 'models/slack_api'
require_relative 'models/slack_token'
require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'
require_relative 'models/user'

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

# Updates the Spotify access and refresh tokens for the given User.
# Returns true on success, false or nil on error.
def update_spotify_tokens(user)
  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                        ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.refresh_tokens(user.spotify_refresh_token)

  if tokens
    user.spotify_access_token = tokens['access_token']
    if (refresh_token = tokens['refresh_token']).present?
      user.spotify_refresh_token = refresh_token
    end
    user.save
  end
end

enable :sessions
set :session_secret, ENV['SESSION_SECRET']

not_found do
  status 404
  erb :not_found
end

# Landing page for the app. User may already be authenticated with
# Slack and Spotify, will redirect if so. Otherwise starts auth
# flow for Spotify.
get '/' do
  if user_id = session[:user_id]
    if user = User.where(id: user_id).first
      if user.signed_into_slack?
        redirect "/user/#{user.to_param}"
      else
        redirect "/auth/spotify/#{user.to_param}"
      end

      return
    end
  end

  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/spotify")
  erb :index
end

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end

# User is authenticated with Spotify but not with Slack.
get '/auth/spotify/:id-:user_name' do
  unless session[:user_id].to_s == params['id'].to_s
    redirect '/'
    return
  end

  @user = User.where(id: params['id'], user_name: params['user_name']).first

  if @user.signed_into_slack?
    redirect "/user/#{@user.to_param}"
    return
  end

  @client_id = ENV['SLACK_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/slack")

  if @user
    erb :spotify_signed_in
  else
    status 404
    erb :not_found
  end
end

# User is authenticated with both Spotify and Slack.
get '/user/:id-:user_name' do
  unless session[:user_id].to_s == params['id'].to_s
    redirect '/'
    return
  end

  @user = User.where(id: params['id'], user_name: params['user_name']).first

  spotify_api = SpotifyApi.new(@user.spotify_access_token)
  @currently_playing = begin
    spotify_api.get_currently_playing
  rescue Fetcher::Unauthorized
    if update_spotify_tokens(@user)
      spotify_api = SpotifyApi.new(@user.spotify_access_token)
      spotify_api.get_currently_playing
    else
      status 400
      return "Failed to get current Spotify track."
    end
  end

  @slack_token = @user.latest_slack_token

  slack_api = SlackApi.new(@slack_token.token)
  if team_info = slack_api.get_team
    @team_image = team_info['icon']['image_44']
  end

  if @user
    erb :fully_signed_in
  else
    status 404
    erb :not_found
  end
end

post '/update-status' do
  user = User.where(id: session[:user_id]).first

  unless user
    status 404
    erb :not_found
    return
  end

  slack_api = SlackApi.new(user.slack_access_token)
  success = slack_api.set_status(params['status'])

  if success
    redirect "/user/#{user.to_param}"
  else
    status 400
    "Failed to update Slack status."
  end
end

# Callback for Slack OAuth authentication.
get '/callback/slack' do
  code = params['code']
  redirect_uri = "#{request.base_url}/callback/slack"

  slack_auth_api = SlackAuthApi.new(ENV['SLACK_CLIENT_ID'],
                                    ENV['SLACK_CLIENT_SECRET'])
  token = slack_auth_api.get_token(code, redirect_uri)

  if token
    slack_api = SlackApi.new(token)

    if team_info = slack_api.get_team
      slack_token = SlackToken.new(user_id: session[:user_id])
      slack_token.token = token
      slack_token.team_id = team_info['id']
      slack_token.team_name = team_info['name']

      if slack_token.save
        redirect "/user/#{slack_token.user.to_param}"
      else
        status 422
        "Failed to save Slack team info: #{slack_token.errors.full_messages.join(', ')}"
      end
    else
      status 400
      "Failed to load Slack team information."
    end
  else
    status 401
    "Failed to authenticate with Slack."
  end
end

# Callback for Spotify OAuth authentication.
get '/callback/spotify' do
  code = params['code']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")

  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                        ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.get_tokens(code, redirect_uri)

  if tokens
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    spotify_api = SpotifyApi.new(access_token)

    if me = spotify_api.get_me
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
