require_relative 'plugin_base'

class PluginVersion < PluginBase
  attr_accessor :manifest

  def initialize(options)
    super(options)
    check_manifest_version_validity
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
    @plugin.find_zapp_plugin
    @id ? update : create
  end

  private

  def create
    @create_new_plugin ? @plugin.create : @plugin.update
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

  def check_manifest_version_validity
    Versionomy.parse(@manifest["manifest_version"])
  rescue => error
    color "Plugin version #{@manifest["manifest_version"]} is not valid", :red
    exit
  end

  def request_params
    {}.tap do |params|
      params["id"] = @id unless @id.nil?
      params["access_token"] = @access_token
      params["plugin_version[plugin_id]"] = @plugin.id
      params["plugin_version[manifest]"] = @manifest.to_json
      params["plugin_version[author_email]"] = @manifest["author_email"]
      params["plugin_version[version]"] = @manifest["manifest_version"]
      params["plugin_version[platform]"] = platform
      params["plugin_version[scheme]"] = @manifest["scheme"]
    end
  end

  def platform
    return if @manifest["platform"].nil? || @manifest["platform"].empty?
    @manifest["platform"]
  end
end
