class PluginBase
  include NetworkHelpers

  attr_accessor :id, :name, :identifier, :manifest

  def initialize(options)
    @create_new_plugin = options.new
    @manifest = get_manifest_data(options)
    @name = @manifest["name"]
    @plugin_guide = get_markdown_data(options.plugin_guide) || @manifest["guide"]
    @plugin_about = get_markdown_data(options.plugin_about) || @manifest["about"]
    @identifier = format_identifier(@manifest["identifier"])
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

  def targets_url
    "#{@base_url}/targets"
  end

  def get_manifest_data(options)
    manifest_file = File.open(options.manifest)
    JSON.parse(File.read(manifest_file))
  end

  def get_markdown_data(markdown_file)
    return unless markdown_file
    File.read(File.open(markdown_file)).gsub!("\n", "\r\n") #required for Zapp to be able to parse line break on md content
  end

  def format_identifier(identifier)
    identifier.gsub(/((_|-)(ios|android))/i, "")
  end
end
