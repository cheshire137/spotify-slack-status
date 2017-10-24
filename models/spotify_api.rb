require_relative 'fetcher'

class SpotifyApi < Fetcher
  def initialize(token, logger:)
    super('https://api.spotify.com/v1', token: token, logger: logger)
  end

  # "https://open.spotify.com/user/wizzler" => "wizzler"
  def self.get_user_name(url)
    url.split('/user/').last
  end

  # https://developer.spotify.com/web-api/get-the-users-currently-playing-track/
  def get_currently_playing
    path = '/me/player/currently-playing'
    logger.info "GET #{base_url}#{path}"
    json = get(path)

    unless json
      logger.error("#{response_code} #{response_body}") unless response_code == '200'
      return
    end

    item = json['item']
    name = item['name']
    artists = item['artists'].map { |artist| artist['name'] }

    "#{name} by #{artists.join(', ')}"
  end

  # https://developer.spotify.com/web-api/get-current-users-profile/
  def get_me
    path = '/me'
    logger.info "GET #{base_url}#{path}"
    json = get(path)

    unless json
      logger.error "#{response_code} #{response_body}"
      return
    end

    json
  end

  private

  def get_headers
    { 'Authorization' => "Bearer #{token}" }
  end
end
