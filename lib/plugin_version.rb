require_relative 'plugin_base'

class PluginVersion < PluginBase
  attr_accessor :manifest

  def initialize(options)
    super(options)
    @id = options.plugin_id || nil
    @plugin = Plugin.new(options)
  end

  def current_manifest
    return unless @id
    manifest_request = get_request(manifest_url + "/#{@id}", { "access_token" => @access_token })

    if manifest_request.response.code.to_i > 400
      color "Failed to update plugin. check if id #{@id} exists", :red
      exit
    end

    manifest_request.body
  end

  def show_diff
    diff = Diffy::SplitDiff.new(
      JSON.pretty_generate(current_manifest),
      JSON.pretty_generate(@manifest),
      format: :color,
    )

    table = Terminal::Table.new do |t|
      t << ["Remote Manifest", "Local Manifest"]
      t << :separator
      t.add_row [diff.left, diff.right]
    end

    color "Showing diff...", :green
    puts table

    abort unless agree "Are you sure? (This will override an existing plugin)"
  end

  def publish
    @id ? update : create
  end

  private

  def create
    @plugin.create if @plugin.id.nil?
    post_request(plugin_versions_url, request_params).response
  end

  def update
    if @plugin.id
      @plugin.update
      put_request(plugin_versions_url + "/#{@id}", request_params).response
    else
      color "Plugin #{@manifest["name"]} not found, cannot proceed with update", :red
      exit
    end
  end

  def request_params
    {}.tap do |params|
      params["id"] = @id unless @id.nil?
      params["access_token"] = @access_token
      params["plugin_version[plugin_id]"] = @plugin.id
      params["plugin_version[manifest]"] = @manifest.to_json
      params["plugin_version[author_email]"] = @manifest["author_email"]
      params["plugin_version[version]"] = @manifest["manifest_version"]
      params["plugin_version[platform]"] = @manifest["platform"]
      params["plugin_version[scheme]"] = @manifest["scheme"]
      params["plugin_version[whitelisted_account_ids][]"] = @manifest["whitelisted_account_ids"]
    end
  end
end
