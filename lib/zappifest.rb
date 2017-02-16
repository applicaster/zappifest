require 'rubygems'
require 'commander/import'
require 'json'
require 'uri'
require 'inquirer'
require 'net/http'
require 'diffy'
require 'terminal-table'
require_relative 'multipart'
require_relative 'network_helpers'
require_relative 'manifest_helpers'
require_relative 'question'

program :name, 'Zappifest'
program :version, '0.22.0'
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

    manifest_hash = { api: {}, dependency_repository_url: [] }

    manifest_hash[:author_name] = Question.ask_non_empty("Author Name:", "author")

    manifest_hash[:author_email] = ask("[?] Author Email: ") do |q|
      q.validate = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      q.responses[:not_valid] = "Should be a valid email."
    end

    manifest_hash[:manifest_version] = ask("[?] Manifest version: ") { |q| q.default = "0.1.0" }
    manifest_hash[:name] = Question.ask_non_empty("Plugin Name:", "name")
    manifest_hash[:description] = Question.ask_non_empty("Plugin description:", "description")
    manifest_hash[:identifier] = Question.ask_non_empty("Plugin identifier:", "identifier")

    type_index = Ask.list "[?] Category", ManifestHelpers::CATEGORIES
    manifest_hash[:type] = ManifestHelpers::CATEGORIES[type_index]

    platform_index = Ask.list "[?] Platform", ManifestHelpers::PLATFORMS
    manifest_hash[:platform] = ManifestHelpers::PLATFORMS[platform_index]

    # temporary: supporting ios parsing - differentiate platforms
    if manifest_hash[:platform] == :android
      dependency_repositories_count = ask(
        "[?] Number of additional dependency repositories that will be in use: ",
        Integer
      ) { |q| q.in = 0..50 }

      if dependency_repositories_count > 0
        manifest_hash[:dependency_repository_url] = [].tap do |result|
          dependency_repositories_count.times do
            repo_url = Question.ask_base("Repository URL:")
            repo_username = Question.ask_base("Username:")
            repo_password = ask("[?] Password: ") { |q| q.echo = "*" }

            result.push(
              { url: repo_url, credentials: { username: repo_username, password: repo_password } }
            )
          end
        end
      end
    else
      # ios or tvos
      manifest_hash[:dependency_repository_url] = ask(
      "[?] Repository urls (optional, will use default ones if blank. " +
      "URLs must be valid, otherwise will not be saved. " +
      "Press 'return' key between values, and 'return key' to finish):",
      -> (repo) { repo =~ /^$|#{URI::regexp(%w(http https))}/ ? repo : nil } ) { |q| q.gather = "" }
    end

    manifest_hash[:min_zapp_sdk] = Question.ask_base("Min Zapp SDK: (Leave blank if no restrictions)")
    manifest_hash[:dependency_name] = Question.ask_non_whitespaces("Package name:", "Package name")
    manifest_hash[:dependency_version] = Question.ask_non_whitespaces("Package version:", "Package version")
    manifest_hash[:api][:class_name] = Question.ask_non_empty("Class Name:", "Class Name")

    if manifest_hash[:platform] == :android
      add_proguard_rules = agree "[?] Need to add custom Proguard rules? (will open a text editor)"
      if add_proguard_rules
        manifest_hash[:api][:proguard_rules] = ask_editor(nil, "vim")
      end
    end

    manifest_hash[:react_native] = agree "[?] React Native plugin? (Y/n)"

    if manifest_hash[:react_native]
      manifest_hash[:extra_dependencies] = []

      extra_dependencies_count = ask("[?] Number of extra dependencies: ", Integer) { |q| q.in = 1..10 }

      extra_dependencies_count.times do |index|
        dependency = {}
        color "Dependency #{index + 1}", :yellow
        color "---------------------", :yellow

        name = Question.ask_non_whitespaces("Dependency Name:", "Dependency Name")
        description = manifest_hash[:platform] == :android ? "e.g. 1.0, 4.8+, etc." : "e.g. ~> 1.0, >= 3.0, :path => 'path/to/dependency', etc."
        parameters = Question.ask_base("Dependency Parameters: (#{description})")
        dependency[name] = parameters
        manifest_hash[:extra_dependencies].push(dependency)
        color "#{name} dependency added!", :green
      end

      manifest_hash[:npm_dependencies] = ask "[?] NPM dependencies: (e.g. module@0.38.0 or blank line to continue)" do |q|
        q.gather = ""
      end

      if manifest_hash[:platform] == :android
        manifest_hash[:react_packages] = ask "[?] React Packages: (or blank line to quit)" do |q|
          q.gather = ""
        end
      end
    end

    say "Custom configuration fields: \n"
    add_custom_fields = agree "[?] Wanna add custom fields? "

    if add_custom_fields
      manifest_hash[:custom_configuration_fields] = []

      custom_fields_count = ask("[?] How many? ", Integer) { |q| q.in = 1..10 }

      custom_fields_count.times do |index|
        field_hash = {}
        color "Custom field #{index + 1}", :yellow
        color "---------------------", :yellow

        input_type_index = Ask.list "[?] Input field type", ManifestHelpers::INPUT_FIELD_TYPES
        field_hash[:type] = ManifestHelpers::INPUT_FIELD_TYPES[input_type_index]

        field_hash[:key] = Question.ask_non_whitespaces("What is the key for this field?", "Custom key")

        if field_hash[:type] == :dropdown
            field_hash[:multiple] = agree "[?] Multiple select?"
            field_hash[:options] = ask "[?] Enter dropdown options (or blank line to quit)" do |q|
              q.gather = ""
            end
        end

        case field_hash[:type]
        when :dropdown
          if field_hash[:multiple]
            booleans_array = Ask.checkbox "[?] Select defaults", field_hash[:options] + ["No Default"]
            default_indices = booleans_array.each_index.select { |i| booleans_array[i] == true }
            values = field_hash[:options].values_at(*default_indices)
            default = values.include?("No Default") ? "" : values
          else
            default_index = Ask.list "[?] Select default", field_hash[:options] + ["No Default"]
            value = field_hash[:options][default_index]
            default = value == "No Default" ? "" : value
          end
        when :checkbox
          default =  Ask.list "[?] Select default", %w(0 1)
        when :tags
          default = Question.ask_base "Default values: (comma seperated)"
          default.gsub!(" ", "")
        else
          default = Question.ask_base "What is the default value?"
        end

        field_hash[:default] = default unless default.to_s.empty?

        manifest_hash[:custom_configuration_fields].push(field_hash)
        color "Custom field #{index + 1} added!", :green
      end
    end

    File.open("plugin-manifest.json", "w") do |file|
      file.write(JSON.pretty_generate(manifest_hash))
    end

    color "plugin-manifest.json file created!", :green
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
    headers.merge!({"User-Agent" => "Zappifest/0.22"})

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

