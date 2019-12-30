require_relative 'plugin_base'

class Plugin < PluginBase
  attr_accessor :id

  def initialize(options)
    super(options)
    @id = @existing_plugin["id"] unless @existing_plugin.nil? 
  end

  def create
    plugin = post_request(plugins_url, request_params).body
    @id = plugin["id"]
    self
  end

  def update
    return unless plugin_requires_update?
    keys_to_remove = ["plugin[account_id]", "plugin[whitelisted_account_ids][]"]
    normalized_params = request_params.delete_if { |key, _| keys_to_remove.include? key }
    
    put_request(plugins_url + "/#{@id}", normalized_params).response
  end 

  private

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
      about
      preview_image
      ui_builder_support
      cover_image
      configuration_panel_disabled
      description
      core_plugin
      screen
      exports
    )
  end

  def new_plugin_attributes
    %w(
      plugin[name]
      plugin[category]
      plugin[whitelisted_account_ids][]
      plugin[about]
      plugin[preview_image]
      plugin[ui_builder_support]
      plugin[cover_image]
      plugin[configuration_panel_disabled]
      plugin[description]
      plugin[core_plugin]
      plugin[screen]
      plugin[exports]
    )
  end
end
