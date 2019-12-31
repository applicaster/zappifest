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
require_relative 'plugin_version'
require_relative 'plugin'
require_relative 'version_helper'

program :name, 'Zappifest'
program :version, VERSION
program :description,
  "Tool to generate Zapp plugin manifest\n.....................................\nDetailed documentation:\nzappifest publish --help\nzappifest init --help"

command :init do |c|
  c.syntax = 'zappifest init [options]'
  c.summary = 'Initialize plugin-manifest.json'
  c.description = 'Initialize plugin-manifest.json'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.action do |args, options|
    options.default access_token: ENV["ZAPP_TOKEN"]

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

command :publish do |c|
  c.syntax = 'zappifest publish [options]'
  c.summary = 'Publish plugin to Zapp'
  c.description = 'Publish zapp plugin-manifest.json to Zapp'
  c.option '--plugin-id PLUGIN_ID', String, 'Zapp plugin id, if updating an existing plugin'
  c.option '--manifest PATH', String, 'plugin-manifest.json path'
  c.option '--access-token ACCESS_TOKEN', String, 'Zapp access-token'
  c.option '--base-url URL', String, 'alternate Zapp server url'
  c.option '--accounts-url URL', String, 'alternate Accounts server url'
  c.option '--new', String, 'use this option to publish a new plugin with a new identifier'
  c.option '--plugin-guide PATH', String, 'markdown file for the plugin guide'
  c.option '--plugin-about PATH', String, 'markdown file for the plugin description'
  c.action do |args, options|
    options.default access_token: ENV["ZAPP_TOKEN"]
    options.default base_url: NetworkHelpers::ZAPP_URL
    options.default accounts_url: NetworkHelpers::ACCOUNTS_URL
    options.default manifest: args.first

    VersionHelper.new(c).check_version
    NetworkHelpers.validate_token(options)

    color "Gathering plugin information...", :green

    plugin_version = PluginVersion.new(options)

    unless ManifestHelpers.valid_account_ids?(plugin_version, options.new)
      color "Manifest must contain at least one whitelisted account id", :red
      exit
    end

    diff_keys = plugin_version.manifest.keys - ManifestHelpers.whitelisted_keys
    missing_keys = ManifestHelpers.mandatory_keys(options.new) - plugin_version.manifest.keys

    if diff_keys.any?
      color "Manifest contains unpermitted keys: #{diff_keys.to_s}", :red
      exit
    end

    if missing_keys.any?
      color "Manifest missing mandatory keys: #{missing_keys.to_s}", :red
      exit
    end

    begin
      color "Publishing your plugin, this will only take a few moments...", :green
      plugin_version.show_diff if plugin_version.id
      response = plugin_version.publish

    rescue => error
      color "Failed with the following error: #{error.message}", :red
    end

    case response
    when Net::HTTPSuccess
      color(options.plugin_id ? "Plugin updated!" : "Plugin created! ", :green)
    when Net::HTTPInternalServerError
      color "Request failed: HTTPInternalServerError", :red
    else
      color "Error: #{response.body}", :red
    end
  end
end
