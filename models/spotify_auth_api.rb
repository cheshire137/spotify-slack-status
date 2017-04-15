class SpotifyAuthApi
  def initialize(client_id, client_secret)
    @client_id = client_id
    @client_secret = client_secret
  end

  def refresh_tokens(refresh_token)
    grant = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    uri = URI.parse('https://accounts.spotify.com/api/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = { 'Authorization' => "Basic #{grant}" }
    req = Net::HTTP::Post.new(uri.request_uri, headers)
    data = { 'grant_type' => 'refresh_token',
             'refresh_token' => refresh_token }
    req.set_form_data(data)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      json = JSON.parse(res.body)
      json.slice('access_token', 'refresh_token')
    end
  end

  def get_tokens(code, redirect_uri)
    grant = Base64.strict_encode64("#{@client_id}:#{@client_secret}")

    uri = URI.parse('https://accounts.spotify.com/api/token')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    headers = { 'Authorization' => "Basic #{grant}" }
    req = Net::HTTP::Post.new(uri.request_uri, headers)
    data = { 'grant_type' => 'authorization_code',
             'code' => code, 'redirect_uri' => redirect_uri }
    req.set_form_data(data)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      json = JSON.parse(res.body)
      json.slice('access_token', 'refresh_token')
    end
  end
end
