require_relative 'plugin_base'

class Plugin < PluginBase
  def initialize(options)
    super(options)
    @existing_plugin = zapp_plugin
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
    get_request(plugins_url, request_params)
      .body
      .select { |p| p["name"] == @name || p["external_identifier"] == @identifier }
      .first
  end

  def request_params
    {}.tap do |params|
      params["id"] = @id unless @id.nil?
      params["access_token"] = @access_token
      params["plugin[name]"] = @manifest["name"]
      params["plugin[category]"] = @manifest["type"]
      params["plugin[external_identifier]"] = @manifest["identifier"]
      params["plugin[whitelisted_account_ids][]"] = @manifest["whitelisted_account_ids"]
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
      external_identifier
      whitelisted_account_ids
    )
  end

  def new_plugin_attributes
    %w(
      plugin[name]
      plugin[category]
      plugin[external_identifier]
      plugin[whitelisted_account_ids][]
    )
  end
end
