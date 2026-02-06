require 'rubygems'
require 'commander/import'
require 'json'
require 'uri'
require 'inquirer'
require 'net/http'
require 'diffy'
require 'terminal-table'
require 'readline'

require_relative 'version'
require_relative 'multipart'
require_relative 'network_helpers'
require_relative 'manifest_helpers'
require_relative 'default_questions_helper'
require_relative 'react_native_questions_helper'
require_relative 'api_questions_helper'
require_relative 'custom_fields_questions_helper'
require_relative 'data_source_provider_questions_helper'
require_relative 'navigation_plugins_questions_helper'
require_relative 'question'
require_relative 'version_helper'
require_relative 'plugin_version'
require_relative 'plugin'
require_relative 'account_helper'


program :name, 'Zappifest'
program :version, VERSION
program :description,
  "Tool to generate Zapp plugin manifest\n.....................................\nDetailed documentation:\n" +
  "zappifest publish --help\n" +
  "zappifest init --help\n" +
  "zappifest get_account_plugins --help\n" +
  "zappifest show_accounts --help\n"

command :init do |c|
  c.syntax = 'zappifest init [options]'
  c.summary = 'Initialize plugin-manifest.json'
  c.description = 'Initialize plugin-manifest.json'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.option '--base-url URL', String, 'alternate Zapp server url'
  c.option '--accounts-url URL', String, 'alternate Accounts server url'
  c.action do |args, options|
    options.default access_token: ENV["ZAPP_TOKEN"]
    options.default base_url: NetworkHelpers::ZAPP_URL
    options.default accounts_url: NetworkHelpers::ACCOUNTS_URL

    VersionHelper.new(options).check_version

    color(
      "      '########::::'###::::'########::'########::'####:'########:'########::'######::'########:
      ..... ##::::'## ##::: ##.... ##: ##.... ##:. ##:: ##.....:: ##.....::'##... ##:... ##..::
      :::: ##::::'##:. ##:: ##:::: ##: ##:::: ##:: ##:: ##::::::: ##::::::: ##:::..::::: ##::::
      ::: ##::::'##:::. ##: ########:: ########::: ##:: ######::: ######:::. ######::::: ##::::
      :: ##::::: #########: ##.....::: ##.....:::: ##:: ##...:::: ##...:::::..... ##:::: ##::::
      : ##:::::: ##.... ##: ##:::::::: ##::::::::: ##:: ##::::::: ##:::::::'##::: ##:::: ##::::
       ########: ##:::: ##: ##:::::::: ##::::::::'####: ##::::::: ########:. ######::::: ##::::
      ........::..:::::..::..:::::::::..:::::::::....::..::::::::........:::......::::::..:::::\n",
      :blue,
    )

    color "This utility will walk you through creating a plugin-manifest.json file.", :green
    color "It only covers the most common items, and tries to guess sensible defaults.", :green
    color "Full documentation regarding the different keys can be found here - https://developer-zapp.applicaster.com/zappifest/plugins-manifest-format.html \n", :green

    manifest_hash = DefaultQuestionsHelper.ask_base_questions(options)

    if manifest_hash[:type].to_s == "data_source_provider"
      DataSourceProviderQuestionsHelper.ask_data_provider_questions(manifest_hash)
    else
      NavigationPluginsQuestionsHelper.ask_nav_items(manifest_hash)
      ApiQuestionsHelper.ask_for_api(manifest_hash)
      ReactNativeQuestionsHelper.ask_for_react_native(manifest_hash)
      CustomFieldsQuestionsHelper.ask_for_custom_fields(manifest_hash)
    end

    ManifestHelpers.create_file(manifest_hash)

    color(
      "#{'🔥'.encode('utf-8')} #{'🔥'.encode('utf-8')} #{'🔥'.encode('utf-8')}  plugin-manifest.json file created!",
      :green,
    )
  end
end

command :get_account_plugins do |c|
  c.syntax = 'zappifest get_account_plugins [options]'
  c.summary = 'Get account plugins'
  c.description = 'Get all plugins of certain account'
  c.option '--account ACCOUNT', String, 'Plugin account id'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.option '--base-url URL', String, 'alternate Zapp server url'
  c.option '--accounts-url URL', String, 'alternate Accounts server url'
  c.action do |args, options|
    options.default access_token: ENV["ZAPP_TOKEN"]
    options.default base_url: NetworkHelpers::ZAPP_URL
    options.default accounts_url: NetworkHelpers::ACCOUNTS_URL
    current_user = NetworkHelpers.validate_token(options).body
    account_helper = AccountHelper.new(current_user, options.account)

    unless account_helper.valid_account?(options)
      color "Please enter a valid account ID as --account option", :red
      exit
    end

    unless account_helper.permitted_account_developer?
      color "You are not permitted to see this account’s plugins, please contact support", :red
      exit
    end

    color "List of #{account_helper.account_name} account plugins", :green

    account_helper.account_plugins(options).each_with_index do |plugin, index|
      color "#{index + 1} #{plugin}"
    end
  end
end

command :show_accounts do |c|
  c.syntax = 'zappifest show_accounts [options]'
  c.summary = 'Show accounts list'
  c.description = 'Get list of permitted accounts'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.option '--accounts-url URL', String, 'alternate Accounts server url'
  c.action do |args, options|
    options.default access_token: ENV["ZAPP_TOKEN"]
    options.default accounts_url: NetworkHelpers::ACCOUNTS_URL
    current_user = NetworkHelpers.validate_token(options).body

    color "Listing accounts and ids (please wait a moment)", :green

    table = Terminal::Table.new do |t|
      t << ["Name", "ID"]
      t << :separator
      parsed_response = NetworkHelpers.get_accounts_list(options).body.each do |account|
        t.add_row [account['name'], account['old_id']]
      end
    end

    puts table
  end
end

command :publish do |c|
  c.syntax = 'zappifest publish [manifest_paths] [options]'
  c.summary = 'Publish plugin(s) to Zapp'
  c.description = 'Publish zapp plugin-manifest.json to Zapp'
  c.option '--plugin-id PLUGIN_ID', String, 'Zapp plugin id, if updating an existing plugin'
  c.option '--manifest PATH', String, 'plugin-manifest.json path'
  c.option '--account ACCOUNT', String, 'Plugin account id'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.option '--base-url URL', String, 'alternate Zapp server url'
  c.option '--accounts-url URL', String, 'alternate Accounts server url'
  c.option '--new', String, 'use this option to publish a new plugin with a new identifier'
  c.option '--plugin-guide PATH', String, 'markdown file for the plugin guide'
  c.option '--plugin-about PATH', String, 'markdown file for the plugin description'
  c.option '--parallel NUM', Integer, 'Number of parallel threads (optional)'
  c.option '--no-diff', 'Do not show diff before publishing'
   c.action do |args, options|
     # Defaults
     options.default access_token: ENV["ZAPP_TOKEN"]
     options.default base_url: NetworkHelpers::ZAPP_URL
     options.default accounts_url: NetworkHelpers::ACCOUNTS_URL
     options.default no_diff: false
     # Note: Do not default :parallel to preserve sequential behavior when not provided
     options.default manifest: args.first

    # Support both --manifest and positional globbing arguments
    manifest_paths = ([options.manifest] + args).compact.uniq

    if manifest_paths.empty?
      color "Missing required manifest path(s).", :red
      exit
    end

    VersionHelper.new(c).check_version

    # GLOBAL STARTUP: validate token & account once
    current_user = NetworkHelpers.validate_token(options).body
    account_helper = AccountHelper.new(current_user, options.account)

    unless account_helper.valid_account?(options) && account_helper.permitted_account_developer?
      color "Account validation failed or insufficient permissions", :red
      exit
    end

    # Fetch global metadata ONCE to avoid redundant calls per manifest
    color "Fetching global Zapp metadata...", :green
    cached_data = {}
    begin
      cached_data[:targets] = NetworkHelpers.get_request("#{options.base_url}/targets", { "access_token" => options.access_token }, { fail_fast: true }).body
      cached_data[:ui_frameworks] = NetworkHelpers.get_request("#{options.base_url}/ui_frameworks", { "access_token" => options.access_token }, { fail_fast: true }).body
    rescue => e
      color "Failed to fetch global metadata: #{e.message}", :red
      exit
    end

    # Decide between parallel or sequential execution
    if options.respond_to?(:parallel) && options.parallel && options.parallel.to_i > 1
      require 'parallel'
      color "Starting parallel publish (#{options.parallel} threads) for #{manifest_paths.size} plugins...", :green
      Parallel.each(manifest_paths, in_threads: options.parallel.to_i) do |path|
        process_single_manifest(path, options, cached_data)
      end
    else
      color "Starting sequential publish for #{manifest_paths.size} plugins...", :green
      manifest_paths.each do |path|
        process_single_manifest(path, options, cached_data)
      end
    end
   end
 end

 # Helper to maintain clean logging and error handling per plugin
 def process_single_manifest(path, options, cached_data)
   begin
     local_options = options.dup
     local_options.manifest = path
     # Inject cached data into options for PluginVersion to use
     local_options.instance_variable_set(:@cached_metadata, cached_data)

     color "[#{path}] Gathering plugin information...", :blue
     plugin_version = PluginVersion.new(local_options)

     # Authorization check for existing plugin - keep per-manifest
     if plugin_version.existing_plugin && plugin_version.existing_plugin["owner_account_id"] != local_options.account
       color "[#{path}] You are not authorized to update this plugin, please contact support", :red
       return
     end

     # Basic validation
     diff_keys = plugin_version.manifest.keys - ManifestHelpers.whitelisted_keys
     missing_keys = ManifestHelpers.mandatory_keys(local_options.new) - plugin_version.manifest.keys

     if diff_keys.any?
       color "[#{path}] Validation failed: Manifest contains unpermitted keys: #{diff_keys.to_s}", :red
       return
     end

     if missing_keys.any?
       color "[#{path}] Validation failed: Manifest missing mandatory keys: #{missing_keys.to_s}", :red
       return
     end

    # Show diff unless explicitly disabled
    plugin_version.show_diff if plugin_version.id && !local_options.no_diff

     color "[#{path}] Publishing...", :green
     response = plugin_version.publish

     if response.is_a?(Net::HTTPSuccess)
       color "[#{path}] Plugin successfully published!", :green
     else
       code = response.respond_to?(:code) ? response.code : 'N/A'
       body = response.respond_to?(:body) ? response.body : response.to_s
       color "[#{path}] Failed: #{code} - #{body}", :red
     end

   rescue => e
     color "[#{path}] Critical Error: #{e.message}", :red
   end
 end
