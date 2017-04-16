require './app'
require 'sinatra/activerecord/rake'

namespace :generate do
  desc 'Generate a crytographically secure secret key.'
  task :secret do
    require 'securerandom'
    puts SecureRandom.hex(64)
  end
end

namespace :spotify do
  desc 'Get an access token for the specified user_name'
  task :access_token, [:user_name] do |t, args|
    user = User.find_by_user_name(args[:user_name])

    unless user
      puts "No user exists with user_name #{args[:user_name]}"
      next
    end

    if user.update_spotify_tokens
      puts "#{user.user_name}'s access token:"
      puts user.spotify_access_token
    else
      puts "Failed to update #{user.user_name}'s access token:"
      puts user.errors.full_messages.join(', ')
    end
  end
end
