require_relative 'fetcher'

class SlackApi < Fetcher
  def initialize(token)
    super('https://slack.com/api', token)
  end
end
