class SlackAuthApi
  def initialize(client_id, client_secret)
    @client_id = client_id
    @client_secret = client_secret
  end

  # https://api.slack.com/docs/oauth
  # https://api.slack.com/methods/oauth.access
  def get_token(code, redirect_uri)
    uri = URI.parse('https://slack.com/api/oauth.access')
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    req = Net::HTTP::Post.new(uri.request_uri)
    data = { 'code' => code, 'redirect_uri' => redirect_uri,
             'client_id' => @client_id,
             'client_secret' => @client_secret }
    req.set_form_data(data)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      json = JSON.parse(res.body)
      json['access_token']
    end
  end
end
