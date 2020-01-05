class AccountHelper
    include NetworkHelpers

    def initialize(user, account)
      @user = user
      @account = account
      @account_name = ""
    end

    def valid_account?(options)
      accounts_list = NetworkHelpers.get_accounts_list(options).body

      return false unless accounts_list.is_a? Array

      existing_account = accounts_list.find { |account| account["old_id"] == @account }
      @account_name = existing_account["name"]
      existing_account.present?
    end

    def account_name
      @account_name
    end

    def account_plugins(options)
      uri = URI.parse(
        "#{options.base_url}/plugins.json?owner_account_id=#{ options.account}",
      )

      plugins = Request.new(uri, { "access_token" => options.access_token }).do_request(:get)

      parsed_plugins = plugins.body.map do |plugin|
        plugin_data ="#{plugin["name"]}, id: #{plugin["id"]}, external identifier: #{plugin["external_identifier"]}, "

        if plugin["latest_versions"].present?
          versions_data = plugin["latest_versions"].map do |version|
            "#{version["version"]} (#{version["platform"]})"
          end
        end

        versions = plugin["latest_versions"].present? ? versions_data.join(', ') : "N/A"

        "#{plugin_data} latest versions: #{versions}"
      end

      parsed_plugins

    end

    def permitted_account_developer?
      account_permission = @user["permissions"].find { |perm| perm["account_id"] == @account }

      return unless account_permission.present?

      return account_permission["roles"].find { |role| role == "zapp:plugin_developer" }.present?
    end
  end