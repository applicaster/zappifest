require_relative 'plugin_base'

class PluginVersion < PluginBase
  attr_accessor :manifest, :plugin

  TARGETS_MAPPER = {
    android: ["mobile"],
    ios: ["mobile"],
    tvos: ["tv"],
    roku: ["tv"],
    samsung_tv: ["tv"],
    android_tv: ["tv"],
  }

  def initialize(options)
    super(options)
    check_manifest_version_validity

    @targets = get_request(targets_url, { "access_token" => @access_token }).body
    set_valid_target

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

  def targets
    @manifest["targets"].map {|target| @targets.select{|t| t["name"] == target}.first["id"] }
  end

  def check_manifest_version_validity
    Versionomy.parse(@manifest["manifest_version"])
  rescue
    color "Plugin version #{@manifest["manifest_version"]} is not valid", :red
    exit
  end

  def set_valid_target
    targets_names = @targets.map {|t| t["name"] }

    if @manifest["targets"].nil? || @manifest["targets"].empty?
      platform = @manifest["platform"]
      return @manifest["targets"] = platform.present? ? TARGETS_MAPPER[platform.to_sym] : ["mobile", "tv"]
    end

    if !@manifest["targets"].all? { |target| targets_names.include?(target) }
      color "Please enter a valid targets, 'mobile' or 'tv' #{targets_names}", :red
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
      params["plugin_version[platform]"] = platform
      params["plugin_version[scheme]"] = @manifest["scheme"]
      params["plugin_version[latest_version]"] = @manifest["latest_version"] || true
      params["plugin_version[targets]"] = targets.to_json
    end
  end

  def platform
    return if @manifest["platform"].nil? || @manifest["platform"].empty?
    @manifest["platform"]
  end
end
