module ManifestHelpers
  WHITELIST_KEYS = [
    "api",
    "author_name",
    "author_email",
    "manifest_version",
    "name",
    "description",
    "identifier",
    "type",
    "platform",
    "dependency_repository_url",
    "min_zapp_sdk",
    "dependency_name",
    "dependency_version",
    "custom_configuration_fields",
    "react_native",
    "extra_dependencies",
    "npm_dependencies",
    "whitelisted_account_ids",
    "data_types",
  ]

  Types = [
    { label: "Player", value: "player", platform_required: true },
    { label: "Navigation", value: "menu", platform_required: true },
    { label: "Analytics Provider", value: "analytics", platform_required: true },
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

  module_function

  def create_file(manifest_hash)
    File.open("plugin-manifest.json", "w") do |file|
      file.write(JSON.pretty_generate(manifest_hash))
    end
  end
end
