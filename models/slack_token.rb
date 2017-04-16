class SlackToken < ActiveRecord::Base
  belongs_to :user

  validates :user, :team_id, :team_name, :token, :slack_user_id,
    :user_name, presence: true
  validates :user_id, uniqueness: { scope: [:team_id, :slack_user_id] }

  scope :for_team, ->(team) { where(team_id: team) }

  scope :for_slack_user, ->(id) { where(slack_user_id: id) }
end
