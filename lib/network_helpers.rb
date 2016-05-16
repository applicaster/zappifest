module NetworkHelpers
  require 'net/http'

  ZAPP_URL = "https://zapp.applicaster.com/api/v1/admin/plugins"

  module_function

  def post_request(url, query, headers)
    Net::HTTP.start(url.host, url.port, use_ssl: url.scheme == "https") do |connection|
      connection.read_timeout = 10
      return connection.post(url.path, query, headers)
    end
  end

  def set_request_params(options)
    manifest_file = File.open(options.manifest)
    manifest_data = JSON.parse(File.read(manifest_file))

    {}.tap do |params|
      params["access_token"] = options.access_token
      params["plugin[manifest]"] = manifest_file
      params["plugin[name]"] = "#{manifest_data['name']}(#{manifest_data['platform']})"
      params["plugin[author_email]"] = manifest_data["author_email"]
    end
  end
end
