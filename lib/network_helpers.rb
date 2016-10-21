module NetworkHelpers
  require 'net/http'

  ZAPP_URL = "https://zapp.applicaster.com/api/v1/admin/plugins"
  ACCOUNTS_URL = "https://accounts.applicaster.com/api/v1"

  module_function

  def validate_accounts_token(options)
    uri = URI.parse(ACCOUNTS_URL)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |connection|
      connection.read_timeout = 10

      return connection.get(
        "#{uri.path}/users/current.json?access_token=#{options.access_token}",
      )
    end
  end

  def post_request(url, query, headers)
    uri = URI.parse(url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |connection|
      connection.read_timeout = 10
      return connection.post(uri.path, query, headers)
    end
  end

  def put_request(url, query, headers)
    uri = URI.parse(url)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |connection|
      connection.read_timeout = 10
      return connection.put(uri.path, query, headers)
    end
  end

  def set_request_params(options)
    manifest_file = File.open(options.manifest)
    manifest_data = JSON.parse(File.read(manifest_file))

    {}.tap do |params|
      params["access_token"] = options.access_token
      params["plugin[manifest]"] = manifest_file
      params["plugin[name]"] = "#{manifest_data['name']} - #{manifest_data['platform']}"
      params["plugin[author_email]"] = manifest_data["author_email"]
      params["plugin[category]"] = manifest_data["type"]
      params["plugin[identifier]"] = manifest_data["identifier"]
      params["plugin[manifest_version]"] = manifest_data["manifest_version"]
      params["plugin[platform]"] = manifest_data["platform"]
    end
  end
end
