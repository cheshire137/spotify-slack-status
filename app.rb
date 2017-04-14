require 'sinatra'
require 'dotenv/load'

get '/' do
  @client_id = ENV['SPOTIFY_CLIENT_ID']
  @redirect_uri = "#{request.base_url}/callback/spotify"
  erb :index
end

get '/callback/spotify' do
end
