class PluginBase
  include NetworkHelpers
  include Question

  attr_accessor :id, :name, :identifier, :manifest, :account_id, :existing_plugin, :request_params

  def initialize(options)
    @create_new_plugin = options.new
    @manifest = get_manifest_data(options)
    @name = @manifest["name"]
    @plugin_guide = get_markdown_data(options.plugin_guide) || @manifest["guide"]
    @plugin_about = get_markdown_data(options.plugin_about) || @manifest["about"]
    @identifier = format_identifier(@manifest["identifier"])
    @base_url = options.override_url || NetworkHelpers::ZAPP_URL
    @access_token = options.access_token
    @plugin_account = options.account
    @existing_plugin = zapp_plugin unless options.new
    @request_params = request_params
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

  private 

  def zapp_plugin
    plugin_candidates = get_request(plugins_url, request_params)
      .body
      .select do |p|
        p["name"] == @name || identifier_matches?(p)
      end
  
    case plugin_candidates.count
    when 0
      color "No Plugin found matching #{@manifest["identifier"]}. please check the identifier and try again", :red
      color "If you want to create a plugin with a new identifier, use the --new option (see zappifest publish --help)", :red
      exit
    when 1
      plugin_candidates.first
    else
      plugin_identifiers = plugin_candidates.map { |p| p["external_identifier"] }
      identifier_index = multiple_option_question("Please select your plugin", plugin_identifiers)
      plugin_candidates[identifier_index]
    end
  end

  def request_params
    {}.tap do |params|
      params["id"] = @existing_plugin["id"] unless @existing_plugin.nil?
      params["access_token"] = @access_token
      params["plugin[name]"] = @name
      params["plugin[category]"] = @manifest["type"]
      params["plugin[external_identifier]"] = @identifier
      params["plugin[whitelisted_account_ids][]"] = @manifest["whitelisted_account_ids"] || @plugin_account
      params["plugin[guide]"] = @plugin_guide
      params["plugin[description]"] = @manifest["description"]
      params["plugin[about]"] = @plugin_about
      params["plugin[core_plugin]"] = @manifest["core_plugin"] || false
      params["plugin[screen]"] = @manifest["screen"] || false
      params["plugin[supports_offline]"] = @manifest["supports_offline"] || false
      params["plugin[exports]"] = plugin_exports?
      params["plugin[configuration_panel_disabled]"] = @manifest["configuration_panel_disabled"] || false
      params["plugin[cover_image]"] = @manifest["cover_image"]
      params["plugin[ui_builder_support]"] = @manifest["ui_builder_support"]
      params["plugin[preview_image]"] = preview_image
      params["plugin[preload]"] = @manifest["preload"] || false
      params["plugin[postload]"] = @manifest["postload"] || false
      params["plugin[account_id]"] = @plugin_account
    end
  end

  def plugin_exports?
    return false unless @manifest["export"]
    @manifest["export"].has_key?("allowed_list")
  end

  def preview_image
    return unless @manifest["preview"]
    previews = @manifest["preview"]["general"]
    return unless previews
    previews.kind_of?(Array) ? previews.first && previews.first["url"] : previews["url"]
  end

  def identifier_matches?(plugin)
    shortened_identifier = format_identifier(@identifier)
    plugin["external_identifier"] == @identifier || plugin["external_identifier"] == shortened_identifier
  end
end
