class User < ActiveRecord::Base
  validates :email, :spotify_access_token, :spotify_refresh_token,
    :user_name, presence: true
  validates :email, uniqueness: true
end
