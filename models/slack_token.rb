class SlackToken < ActiveRecord::Base
  belongs_to :user

  validates :user, :team_id, :team_name, :token, presence: true
end
