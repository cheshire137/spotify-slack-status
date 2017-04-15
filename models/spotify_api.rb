class SpotifyApi
  def initialize(token)
    @token = token
    @base_url = 'https://api.spotify.com/v1'
  end

  # https://developer.spotify.com/web-api/get-the-users-currently-playing-track/
  def get_currently_playing
    json = get('/me/player/currently-playing')

    return unless json

    item = json['item']
    name = item['name']
    artists = item['artists'].map { |artist| artist['name'] }

    "#{name} by #{artists.join(', ')}"
  end

  # https://developer.spotify.com/web-api/get-current-users-profile/
  def get_me
    json = get('/me')

    return unless json

    json
  end

  private

  def get(path)
    uri = URI.parse("#{@base_url}#{path}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    header = { 'Authorization' => "Bearer #{@token}" }
    req = Net::HTTP::Get.new(uri.request_uri, header)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      JSON.parse(res.body)
    end
  end
end
