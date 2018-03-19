module ManifestHelpers
  MANDATORY_KEYS = [
    "author_name",
    "author_email",
    "manifest_version",
    "name",
    "description",
    "identifier",
    "type",
    "min_zapp_sdk",
    "whitelisted_account_ids",
  ]

  OPTIONAL_KEYS = [
    "api",
    "platform",
    "dependency_name",
    "dependency_version",
    "dependency_repository_url",
    "deprecated_since_zapp_sdk",
    "unsupported_since_zapp_sdk",
    "custom_configuration_fields",
    "react_native",
    "extra_dependencies",
    "project_dependencies",
    "npm_dependencies",
    "scheme",
    "data_types",
    "react_bundle_url",
    "thumbnail",
    "screenshots",
    "preview",
    "general",
    "assets",
    "styles",
    "rules",
    "data",
    "supported_nav_items",
  ]

  Types = [
    { label: "Player", value: "player", platform_required: true },
    { label: "Navigation", value: "menu", platform_required: true },
    { label: "Navigation Bar", value: "nav_bar", platform_required: true },
    { label: "Analytics Provider", value: "analytics", platform_required: true },
    { label: "Article", value: "article", platform_required:true },
    { label: "Advertisement", value: "advertisement", platform_required: true },
    { label: "Payments", value: "payments" },
    { label: "Authentication", value: "auth_provider", platform_required: true },
    { label: "Push Provider", value: "push_provider", platform_required: true },
    { label: "Ui Component", value: "ui_component", platform_required: true },
    { label: "Login", value: "login", platform_required: true },
    { label: "Data Source Provider", value: "data_source_provider", platform_required: false },
    { label: "Broadcaster Selector", value: "broadcaster_selector", platform_required: true },
    { label: "General", value: "general", platform_required: true },
  ]

  PLATFORMS = [
    { label: "iOS", value: "ios" },
    { label: "Android", value: "android" },
    { label: "tvOS", value: "tvos" },
    { label: "Android TV", value: "android_tv" },
  ]

  INPUT_FIELD_TYPES = %i(text checkbox textarea dropdown tags colorpicker)

  TOOLTIP_TYPES = [
    { type: :plain, value: "Plain text"},
    { type: :url, value: "A link to an external resource"},
    { type: :mixed, value: "Text with a link to an external resource"}
  ].freeze

  module_function

  def create_file(manifest_hash)
    File.open("plugin-manifest.json", "w") do |file|
      file.write(JSON.pretty_generate(manifest_hash))
    end
  end

  def ensure_whitelisted_accounts(manifest_hash)
    return if manifest_hash.keys.include?("whitelisted_account_ids")
    manifest_hash["whitelisted_account_ids"] = []
  end

  def whitelisted_keys
    MANDATORY_KEYS + OPTIONAL_KEYS
  end
end
