class PluginBase
  include NetworkHelpers

  attr_accessor :id, :name, :identifier

  def initialize(options)
    @manifest = get_manifest_data(options)
    @name = @manifest["name"]
    @identifier = @manifest["identifier"]
    @base_url = options.override_url || NetworkHelpers::ZAPP_URL
    @access_token = options.access_token
  end

  def plugins_url
    "#{@base_url}/plugins"
  end

  def plugin_versions_url
    "#{@base_url}/plugin_versions"
  end

  def manifest_url
    "#{@base_url}/plugin_manifests"
  end

  def get_manifest_data(options)
    manifest_file = File.open(options.manifest)
    JSON.parse(File.read(manifest_file))
  end
end
