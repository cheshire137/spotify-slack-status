class SlackToken < ActiveRecord::Base
  belongs_to :user

  validates :user, :team_id, :team_name, :token, presence: true
  validates :user_id, uniqueness: { scope: :team_id }
end
