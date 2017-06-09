require 'rubygems'
require 'commander/import'
require 'json'
require 'uri'
require 'inquirer'
require 'net/http'
require 'diffy'
require 'pry'
require 'terminal-table'

require_relative 'version'
require_relative 'multipart'
require_relative 'network_helpers'
require_relative 'manifest_helpers'
require_relative 'default_questions_helper'
require_relative 'react_native_questions_helper'
require_relative 'api_questions_helper'
require_relative 'custom_fields_questions_helper'
require_relative 'data_source_provider_questions_helper'
require_relative 'question'

program :name, 'Zappifest'
program :version, VERSION
program :description, 'Tool to generate Zapp plugin manifest'

command :init do |c|
  c.syntax = 'zappifest init [options]'
  c.summary = 'Initialize plugin-manifest.json'
  c.description = 'Initialize plugin-manifest.json'
  c.action do |args, options|

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
    color "It only covers the most common items, and tries to guess sensible defaults.\n", :green

    manifest_hash = DefaultQuestionsHelper.ask_base_questions

    if manifest_hash[:type].to_s == "data_source_provider"
      DataSourceProviderQuestionsHelper.ask_data_provider_questions(manifest_hash)
    else
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
  c.option '--override-url URL', String, 'alternate url'
  c.action do |args, options|
    unless options.override_url
      begin
        accounts_response = NetworkHelpers.validate_accounts_token(options)
      rescue => error
        color "Cannot validate Token. Request failed: #{error}", :red
      end

      case accounts_response
      when Net::HTTPSuccess
        color("Token valid, posting plugin...", :green)
      when Net::HTTPUnauthorized
        color "Invalid token", :red
        exit
      else
        color "Cannot validate token, please try later.", :red
      end
    end

    manifest = JSON.parse(File.open(options.manifest).read)
    diff_keys = manifest.keys - ManifestHelpers::WHITELIST_KEYS

    if diff_keys.any?
      color "Manifest contains unpermitted keys: #{diff_keys.to_s}", :red
      exit
    end

    url = options.override_url || NetworkHelpers::ZAPP_URL
    params = NetworkHelpers.set_request_params(options)
    mp = Multipart::MultipartPost.new
    query, headers = mp.prepare_query(params)
    headers.merge!({"User-Agent" => "Zappifest/#{VERSION}"})

    begin
      if options.plugin_id
        color "Showing diff...", :green
        new_manifest = JSON.parse(File.open(options.manifest).read)

        current_manifest = JSON.parse(
          NetworkHelpers.get_current_manifest(new_manifest["name"], options.plugin_id).body
        )

        diff = Diffy::SplitDiff.new(
          JSON.pretty_generate(current_manifest), JSON.pretty_generate(new_manifest),
          format: :color
        )

        table = Terminal::Table.new do |t|
          t << ["Remote Manifest", "Local Manifset"]
          t << :separator
          t.add_row [diff.left, diff.right]
        end

        puts table

        if agree "Are you sure? (This will override an existing plugin)"
          response = NetworkHelpers.put_request("#{url}/#{options.plugin_id}", query, headers)
        else
          abort
        end
      else
        response = NetworkHelpers.post_request(url, query, headers)
      end
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

