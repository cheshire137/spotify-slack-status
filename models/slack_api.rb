require_relative 'fetcher'

class SlackApi < Fetcher
  def initialize(token, logger:)
    super('https://slack.com/api', token: token, logger: logger)
  end

  # https://api.slack.com/methods/auth.test
  def get_info
    path = '/auth.test'
    logger.info "GET #{base_url}#{path}"
    json = get("#{path}?token=#{token}")

    unless json && json['ok']
      logger.error "#{response_code} #{response_body}"
      return
    end

    json
  end

  def self.valid_status?(status)
    status && status.length > 0 && status.length <= 100
  end

  # https://api.slack.com/methods/users.profile.set
  def set_status(status)
    profile = {
      'status_text' => status,
      'status_emoji' => ':musical_note:'
    }
    data = { 'token' => token, 'profile' => profile.to_json }
    path = '/users.profile.set'
    logger.info "POST #{base_url}#{path}"
    json = post(path) do |req|
      req.set_form_data(data)
    end

    return true if json && json['ok']

    logger.error "#{response_code} #{response_body}"
    false
  end
end
