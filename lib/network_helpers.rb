module NetworkHelpers
  require 'net/http'

  ZAPP_URL = "https://zapp.applicaster.com/api/v1/admin"
  ACCOUNTS_URL = "https://accounts.applicaster.com/api/v1"

  class Request
    attr_accessor :response, :body

    def initialize(uri, params, options = {})
      @uri = uri
      @params = params
      @options = options
    end

    def do_request(method)
      Net::HTTP.start(@uri.host, @uri.port, use_ssl: use_ssl?) do |connection|
        connection.read_timeout = 60
        @method = method
        @response = connection.send(method, request_url, *request_params)
        handle_response
        self
      end
    end

    private

    def request_url
      return @uri.path unless @method == :get
      "#{@uri.path}?access_token=#{@params["access_token"]}&#{@uri.query}"
    end

    def request_params
      return nil if @method == :get
      Multipart::MultipartPost.new.prepare_query(@params)
    end

    def use_ssl?
      @uri.scheme == "https"
    end

    def handle_response
      case @response
      when Net::HTTPOK
        @body = JSON.parse(response.body)
      when Net::HTTPInternalServerError
        color "Request failed: Internal Server Error", :red
        exit if @options[:fail_fast]
      when Net::HTTPUnauthorized
        color "Request failed: Unauthorized, please check your ZAPP_TOKEN", :red
        exit if @options[:fail_fast]
      else
        color "Request failed", :red
        color "Error code: #{@response.code}", :red
        color "Error message: #{@response.message}", :red
        color "Error body: #{@response.body}", :red
        exit if @options[:fail_fast]
      end

    rescue JSON::ParserError => error
      color "Couldn't parse JSON response: #{error}", :red
    end
  end

  module_function

  def current_user(options)
    uri = URI.parse("#{options.accounts_url}/users/current.json")
    Request.new(uri, { "access_token" => options.access_token }).do_request(:get)
  end

  def validate_token(options)
    unless options.access_token
      color "Access token is missing"
      exit
    end

    current_user(options)
  end

  def get_accounts_list(options)
    uri = URI.parse("#{options.accounts_url}/accounts.json")
    Request.new(uri, { "access_token" => options.access_token }).do_request(:get)
  end

  def get_zapp_sdks(platform, options)
    uri = URI.parse(
      "#{options.base_url}/sdk_versions.json?by_platform=#{platform}&status=stable&stable_channel_by_version=true",
    )

    Request.new(uri, { "access_token" => options.access_token }).do_request(:get).response
  end

  def get_request(url, params, options = {})
    Request.new(URI.parse(url), params, options).do_request(:get)
  end

  def post_request(url, params, options = {})
    Request.new(URI.parse(url), params, options).do_request(:post)
  end

  def put_request(url, params, options = {})
    Request.new(URI.parse(url), params, options).do_request(:put)
  end
end
