class User < ActiveRecord::Base
  validates :email, :spotify_access_token, :spotify_refresh_token,
    :user_name, presence: true
  validates :email, uniqueness: true

  has_many :slack_tokens, dependent: :destroy

  def to_param
    "#{id}-#{user_name}"
  end

  def signed_into_slack?
    slack_access_token.present?
  end
end
