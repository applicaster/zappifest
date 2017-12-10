module NetworkHelpers
  require 'net/http'

  ZAPP_URL = "https://zapp.applicaster.com/api/v1/admin/plugin_versions"
  PLUGINS_URL = "https://zapp.applicaster.com/admin/plugin_versions"
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

  def get_current_manifest(plugin_identifier, plugin_id)
    uri = URI.parse(ZAPP_URL)

    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |connection|
      connection.read_timeout = 10

      return connection.get(
        "#{uri.path}/#{plugin_id}/plugin_manifests/#{plugin_identifier}",
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
      params["plugin_version[manifest]"] = manifest_data.to_json
      params["plugin_version[name]"] = manifest_data['name']
      params["plugin_version[author_email]"] = manifest_data["author_email"]
      params["plugin_version[category]"] = manifest_data["type"]
      params["plugin_version[identifier]"] = manifest_data["identifier"]
      params["plugin_version[version]"] = manifest_data["manifest_version"]
      params["plugin_version[platform]"] = manifest_data["platform"]
      params["plugin_version[scheme]"] = manifest_data["scheme"]
      params["plugin_version[whitelisted_account_ids][]"] = manifest_data["whitelisted_account_ids"]
    end
  end
end
