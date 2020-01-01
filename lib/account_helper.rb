class AccountHelper
    include NetworkHelpers

    def initialize(user, account)
      @user = user
      @account = account
    end

    def valid_account?(options)
      accounts_list = NetworkHelpers.get_accounts_list(options).body

      return false unless accounts_list.is_a? Array

      existing_account = accounts_list.find { |account| account["old_id"] == @account }
      existing_account.present?
    end

    def permitted_account_developer?
      account_permission = @user["permissions"].find { |perm| perm["account_id"] == @account }

      return unless account_permission.present?

      return account_permission["roles"].find { |role| role == "zapp:plugin_developer" }.present?
    end
  end