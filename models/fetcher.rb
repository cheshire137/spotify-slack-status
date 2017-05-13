class Fetcher
  class Unauthorized < StandardError; end

  attr_reader :base_url, :token, :logger, :response_code,
    :response_body

  def initialize(base_url, token:, logger:)
    @base_url = base_url
    @token = token
    @logger = logger
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
    @response_code = res.code
    @response_body = res.body

    if res.kind_of? Net::HTTPSuccess
      begin
        JSON.parse(res.body)
      rescue JSON::ParserError
        nil
      end
    elsif res.code == '401'
      raise Unauthorized, res.message
    end
  end

  # Will make a POST request to the given path. Yields the request
  # so the request body can be set.
  def post(path)
    uri = get_uri(path)
    http = get_http(uri)
    req = Net::HTTP::Post.new(uri.request_uri, get_headers)
    yield req if block_given?

    res = http.request(req)
    @response_code = res.code
    @response_body = res.body

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
