require './app'
require 'sinatra/activerecord/rake'

namespace :generate do
  desc 'Generate a crytographically secure secret key.'
  task :secret do
    require 'securerandom'
    puts SecureRandom.hex(64)
  end
end
