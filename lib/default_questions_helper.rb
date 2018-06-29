module DefaultQuestionsHelper
  module_function

  def ask_base_questions(options, manifest_hash = { api: {}, dependency_repository_url: [], platform: nil })
    manifest_hash[:author_name] = Question.ask_non_empty("Author Name:", "author")

    manifest_hash[:author_email] = ask("[?] Author Email: ") do |q|
      q.validate = /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
      q.responses[:not_valid] = "Should be a valid email."
    end

    manifest_hash[:manifest_version] = Question.ask_for_version("Manifest version: ")

    manifest_hash[:name] = Question.ask_non_empty("Plugin Name:", "name")
    manifest_hash[:description] = Question.ask_non_empty("Plugin description:", "description")

    type_index = Ask.list "[?] Plugin Type", ManifestHelpers::Types.map { |type| type[:label] }
    manifest_hash[:type] = ManifestHelpers::Types[type_index][:value]

    manifest_hash[:identifier] = Question.ask_non_empty(
      "Plugin identifier: (Unique identifier for the plugin)",
      "identifier",
    )

    if ManifestHelpers::Types[type_index][:platform_required]
      platform_index = Ask.list "[?] Platform", ManifestHelpers::PLATFORMS.map { |platform| platform[:label] }
      manifest_hash[:platform] = ManifestHelpers::PLATFORMS[platform_index][:value]
    end

    if manifest_hash[:platform].to_s =~ /android/
      ask_for_android_dependency_repositories(manifest_hash)
    else
      ask_for_dependency_repository(manifest_hash)
    end

    manifest_hash[:ui_builder_support] = agree "[?] Should this plugin be available in Zapp UI Builder? (Y/n)"
    package_name = Question.ask_base("Package name:")

    unless package_name.empty?
      manifest_hash[:dependency_name] = package_name
      manifest_hash[:dependency_version] = Question.ask_for_version("Package version:")
    end

    ask_for_whitelisted_accounts(manifest_hash, options)
    manifest_hash[:min_zapp_sdk] = Question.ask_for_version("Min Zapp SDK:")
    manifest_hash[:deprecated_since_zapp_sdk] = Question.ask_for_version("Deprecated since Zapp SDK version:")
    manifest_hash[:unsupported_since_zapp_sdk] = Question.ask_for_version("Unsupported since Zapp SDK:")

    manifest_hash
  end

  def ask_for_whitelisted_accounts(manifest_hash, options)
    begin
      manifest_hash[:whitelisted_account_ids] = []
      say "[?] Whitelisted Accounts"
      color "Loading accounts, please wait a moment...", :green
      response = NetworkHelpers.get_accounts_list(options)
    rescue => error
      color "Cannot load accounts. Request failed: #{error}", :red
      exit
    end

    case response
    when Net::HTTPSuccess
      parsed_response = JSON.parse(response.body).each_with_object({}) do |account, result|
        result[account["name"]] = account["old_id"]
      end

      ask_for_whitelisted_account_ids_input(manifest_hash, parsed_response)
    when Net::HTTPUnauthorized
      color "Invalid token", :red
      exit
    else
      color "Cannot load accounts, please try later.", :red
      exit
    end
  end

  def ask_for_whitelisted_account_ids_input(manifest_hash, accounts)
    comp = proc { |s| accounts.keys.sort.grep(Regexp.new("^" + Regexp.escape(s), "i")) }

    Readline.completion_append_character = nil
    Readline.completion_proc = comp
    say "Account name is case-sensitive. Use the TAB key for autocompletion, press the RETURN key to finish selection"

    while line = Readline.readline("[?] ", true)
      p line

      if line == ""
        if manifest_hash[:whitelisted_account_ids].any?
          break
        else
          say "whitelisted account IDs cannot be empty"
        end
      else
        if accounts[line]
          manifest_hash[:whitelisted_account_ids] << accounts[line]
        else
          say "Account name is incorrect, please make sure you type an exisiting name (case-senesitive)."\
            " Use the TAB key for autocompletion"
        end
      end
    end
  end

  def ask_for_android_dependency_repositories(manifest_hash)
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
  end

  def ask_for_dependency_repository(manifest_hash)
    manifest_hash[:dependency_repository_url] = ask(
      "[?] Repository urls (optional, will use default ones if blank. " +
      "URLs must be valid, otherwise will not be saved. " +
      "Press 'return' key between values, and 'return key' to finish):",
      -> (repo) { repo =~ /^$|#{URI::regexp(%w(http https))}/ ? repo : nil } ) { |q| q.gather = "" }
  end
end
