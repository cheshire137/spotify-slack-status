class User < ActiveRecord::Base
  validates :email, :spotify_access_token, :spotify_refresh_token,
    :user_name, presence: true
  validates :email, uniqueness: true

  has_many :slack_tokens, dependent: :destroy

  def to_param
    "#{id}-#{user_name}"
  end

  def signed_into_slack?
    slack_tokens.count > 0
  end

  def latest_slack_token
    slack_tokens.order("updated_at DESC").first
  end

  # Returns a hash of Slack team IDs and team names, excluding the given
  # SlackToken ID.
  def other_slacks(slack_token_id)
    slack_tokens.where('id <> ?', slack_token_id).
      order(:team_name).select(:team_id, :team_name).
      map { |slack_token| [slack_token.team_id, slack_token.team_name] }.
      to_h
  end

  # Updates the Spotify access and refresh tokens for the given User.
  # Returns true on success, false or nil on error.
  def update_spotify_tokens
    spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                          ENV['SPOTIFY_CLIENT_SECRET'])
    tokens = spotify_auth_api.refresh_tokens(spotify_refresh_token)

    if tokens
      self.spotify_access_token = tokens['access_token']
      if (refresh_token = tokens['refresh_token']).present?
        self.spotify_refresh_token = refresh_token
      end
      save
    end
  end
end
