class Fetcher
  attr_reader :base_url, :token

  def initialize(base_url, token)
    @base_url = base_url
    @token = token
  end

  protected

  def get_headers
    {}
  end

  def get(path)
    uri = get_uri(path)
    http = get_http(uri)

    req = Net::HTTP::Get.new(uri.request_uri, get_headers)

    res = http.request(req)
    if res.kind_of? Net::HTTPSuccess
      JSON.parse(res.body)
    end
  end

  # Will make a POST request to the given path. Yields the request
  # so the request body can be set.
  def post(path)
    uri = get_uri(path)
    http = get_http(uri)

    headers = get_headers
    req = Net::HTTP::Post.new(uri.request_uri, headers)
    yield req

    res = http.request(req)

    if res.kind_of? Net::HTTPSuccess
      JSON.parse(res.body)
    end
  end

  private

  def get_uri(path)
    URI.parse("#{@base_url}#{path}")
  end

  def get_http(uri)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http
  end
end
