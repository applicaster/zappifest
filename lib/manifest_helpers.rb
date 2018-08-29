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
    "ui_builder_support",
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
    "about",
    "general",
    "assets",
    "styles",
    "rules",
    "data",
    "advertising",
    "screen",
    "supported_nav_items",
    "max_nav_items",
    "zapp_configuration",
    "summary",
    "cover_image",
    "guide",
    "core_plugin",
    "configuration_panel_disabled",
  ]

  Types = [
    { label: "Player", value: "player", platform_required: true },
    { label: "Navigation", value: "menu", platform_required: true, screen: false },
    { label: "Navigation Bar", value: "nav_bar", platform_required: true, screen: false },
    { label: "Analytics Provider", value: "analytics", platform_required: true, screen: false },
    { label: "Article", value: "article", platform_required:true, screen: true },
    { label: "Advertisement", value: "advertisement", platform_required: true, screen: false },
    { label: "Payments", value: "payments", screen: false },
    { label: "Authentication", value: "auth_provider", platform_required: true },
    { label: "Push Provider", value: "push_provider", platform_required: true, screen: false },
    { label: "Ui Component", value: "ui_component", platform_required: true, screen: false },
    { label: "Login", value: "login", platform_required: true },
    { label: "Data Source Provider", value: "data_source_provider", platform_required: false, screen: false },
    { label: "Broadcaster Selector", value: "broadcaster_selector", platform_required: true },
    { label: "General", value: "general", platform_required: true },
  ]

  PLATFORMS = [
    { label: "iOS", value: "ios" },
    { label: "Android", value: "android" },
    { label: "tvOS", value: "tvos" },
    { label: "Android TV", value: "android_tv" },
    { label: "Roku", value: "roku" },
  ]

  INPUT_FIELD_TYPES = %i(text checkbox textarea dropdown tags colorpicker uploader)

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

  def whitelisted_keys
    MANDATORY_KEYS + OPTIONAL_KEYS
  end

  def valid_account_ids?(manifest, options)
    return true unless options.new
    manifest["whitelisted_account_ids"] && manifest["whitelisted_account_ids"].any?
  end
end
