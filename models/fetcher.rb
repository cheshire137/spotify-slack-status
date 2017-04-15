class Fetcher
  def initialize(base_url, token)
    @base_url = base_url
    @token = token
  end

  protected

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
