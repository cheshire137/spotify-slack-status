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

def get_spotify_auth_url
  client_id = ENV['SPOTIFY_CLIENT_ID']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")
  scopes = ['user-read-currently-playing', 'user-read-email']

  "https://accounts.spotify.com/authorize?client_id=" +
    "#{client_id}&response_type=code&redirect_uri=" +
    "#{redirect_uri}&scope=#{scopes.join('%20')}"
end

def get_slack_auth_url
  client_id = ENV['SLACK_CLIENT_ID']
  redirect_uri = escape_url("#{request.base_url}/callback/slack")
  scope = 'users.profile:write'

  "https://slack.com/oauth/authorize?client_id=#{client_id}" +
    "&scope=#{scope}&redirect_uri=#{redirect_uri}"
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
        redirect get_slack_auth_url
      end

      return
    end
  end

  @auth_url = get_spotify_auth_url
  erb :index
end

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end

# User is authenticated with both Spotify and Slack and is using a
# particular Slack team they belong to.
get '/user/:id-:user_name/:team_id' do
  unless session[:user_id].to_s == params['id'].to_s
    redirect '/'
    return
  end

  @user = User.where(id: params['id'], user_name: params['user_name']).first

  unless @user
    status 404
    erb :not_found
    return
  end

  @slack_token = @user.slack_tokens.where(team_id: params['team_id']).first

  unless @slack_token
    status 404
    erb :not_found
    return
  end

  spotify_api = SpotifyApi.new(@user.spotify_access_token)
  @currently_playing = begin
    spotify_api.get_currently_playing
  rescue Fetcher::Unauthorized
    if @user.update_spotify_tokens
      spotify_api = SpotifyApi.new(@user.spotify_access_token)
      spotify_api.get_currently_playing
    else
      status 400
      return "Failed to get current Spotify track."
    end
  end

  slack_api = SlackApi.new(@slack_token.token)

  @client_id = ENV['SLACK_CLIENT_ID']
  @redirect_uri = escape_url("#{request.base_url}/callback/slack")

  @other_slacks = @user.other_slacks(@slack_token.id)

  erb :fully_signed_in
end

# User is authenticated with both Spotify and Slack.
get '/user/:id-:user_name' do
  unless session[:user_id].to_s == params['id'].to_s
    redirect '/'
    return
  end

  user = User.where(id: params['id'], user_name: params['user_name']).first

  unless user
    status 404
    erb :not_found
    return
  end

  slack_token = user.latest_slack_token

  unless slack_token
    status 404
    erb :not_found
    return
  end

  redirect "/user/#{user.to_param}/#{slack_token.team_id}"
end

# Callback for Slack command to set the Slack status to the current
# Spotify track.
# See https://api.slack.com/slash-commands
post '/command/spotify-status' do
  unless params['token'] == ENV['SLACK_VERIFICATION_TOKEN']
    status 401
    return 'Invalid verification token'
  end

  unless params['command'] == '/spotify-status'
    status 405
    return 'Invalid command'
  end

  slack_token = SlackToken.for_team(params['team_id']).
    for_slack_user(params['user_id']).first

  unless slack_token
    content_type :json
    json = {
      text: 'Please sign into Spotify first.',
      attachments: [
        {
          title: 'Sign in with Spotify',
          title_link: get_spotify_auth_url
        }
      ]
    }
    return json.to_json
  end

  user = slack_token.user

  spotify_api = SpotifyApi.new(user.spotify_access_token)
  currently_playing = begin
    spotify_api.get_currently_playing
  rescue Fetcher::Unauthorized
    if user.update_spotify_tokens
      spotify_api = SpotifyApi.new(user.spotify_access_token)
      spotify_api.get_currently_playing
    else
      status 400
      return 'Could not get latest Spotify track'
    end
  end

  if currently_playing.present?
    status = currently_playing
    slack_api = SlackApi.new(slack_token.token)
    success = slack_api.set_status(status)

    if success
      content_type :json
      json = {
        text: 'Updated your Slack status.',
        attachments: [
          { title: ":musical_note: #{status}" }
        ]
      }
      json.to_json
    else
      status 400
      content_type :json
      json = {
        text: 'Could not update Slack status.',
        attachments: [
          {
            title: 'Sign in with Spotify',
            title_link: get_spotify_auth_url
          }
        ]
      }
      json.to_json
    end
  else
    content_type :json
    json = {
      text: 'Did not update your Slack status.',
      attachments: [
        { title: "Are you listening to anything on Spotify?" }
      ]
    }
    json.to_json
  end
end

# Update the Slack status for the current user using the specified Slack
# token.
post '/update-status/:slack_token_id' do
  unless session[:user_id]
    redirect '/'
    return
  end

  user = User.where(id: session[:user_id]).first

  unless user
    status 404
    erb :not_found
    return
  end

  slack_token = user.slack_tokens.where(id: params['slack_token_id']).first

  unless slack_token
    status 404
    erb :not_found
    return
  end

  slack_api = SlackApi.new(slack_token.token)
  success = slack_api.set_status(params['status'])

  if success
    redirect "/user/#{user.to_param}/#{slack_token.team_id}"
  else
    status 400
    "Failed to update Slack status."
  end
end

# Callback for Slack OAuth authentication.
get '/callback/slack' do
  # Maybe the user came straight from the Slack app and has not
  # yet signed in via Spotify.
  unless session[:user_id]
    redirect get_spotify_auth_url
    return
  end

  code = params['code']
  redirect_uri = "#{request.base_url}/callback/slack"

  slack_auth_api = SlackAuthApi.new(ENV['SLACK_CLIENT_ID'],
                                    ENV['SLACK_CLIENT_SECRET'])
  token = slack_auth_api.get_token(code, redirect_uri)

  if token
    slack_api = SlackApi.new(token)

    if info = slack_api.get_info
      slack_token = SlackToken.for_team(info['team_id']).
        for_slack_user(info['user_id']).
        for_user(session[:user_id]).first_or_initialize
      slack_token.token = token
      slack_token.team_name = info['team']
      slack_token.user_name = info['user']

      if slack_token.save
        redirect "/user/#{slack_token.user.to_param}/#{slack_token.team_id}"
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
  redirect_uri = "#{request.base_url}/callback/spotify"

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
        redirect get_slack_auth_url
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
