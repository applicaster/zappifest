require_relative 'plugin_base'

class Plugin < PluginBase
  include Question

  def initialize(options)
    super(options)
  end

  def find_zapp_plugin
    @existing_plugin = zapp_plugin unless @create_new_plugin
    @id = @existing_plugin["id"] unless @existing_plugin.nil?
  end

  def create
    plugin = post_request(plugins_url, request_params).body
    @id = plugin["id"]
    self
  end

  def update
    return unless plugin_requires_update?
    put_request(plugins_url + "/#{@id}", request_params).response
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
      identifier_index = multiple_option_question("Please select your plugin :", plugin_identifiers)
      plugin_candidates[identifier_index]
    end
  end

  def identifier_matches?(plugin)
    shortened_identifier = format_identifier(@identifier)
    plugin["external_identifier"] == @identifier || plugin["external_identifier"] == shortened_identifier
  end

  def request_params
    {}.tap do |params|
      params["id"] = @id unless @id.nil?
      params["access_token"] = @access_token
      params["plugin[name]"] = @name
      params["plugin[category]"] = @manifest["type"]
      params["plugin[external_identifier]"] = @identifier
      params["plugin[whitelisted_account_ids][]"] = @manifest["whitelisted_account_ids"]
      params["plugin[guide]"] = @plugin_guide
      params["plugin[description]"] = @manifest["description"]
      params["plugin[about]"] = @plugin_about
      params["plugin[core_plugin]"] = @manifest["core_plugin"] || false
      params["plugin[configuration_panel_disabled]"] = @manifest["configuration_panel_disabled"] || false
      params["plugin[cover_image]"] = @manifest["cover_image"]
      params["plugin[preview_image]"] = preview_image
    end
  end

  def plugin_requires_update?
    return if @existing_plugin.nil?
    @existing_plugin.values_at(*existing_plugin_attributes) !=
      request_params.values_at(*new_plugin_attributes)
  end

  def existing_plugin_attributes
    %w(
      name
      category
      whitelisted_account_ids
    )
  end

  def new_plugin_attributes
    %w(
      plugin[name]
      plugin[category]
      plugin[whitelisted_account_ids][]
    )
  end

  def preview_image
    previews = @manifest.dig("preview", "general")
    return if previews.nil?

    previews.class == Array ? previews.first&.dig("url") : previews.dig("url")
  end
end
