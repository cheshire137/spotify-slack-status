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
end
