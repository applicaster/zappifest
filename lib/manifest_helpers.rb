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
  ]

  CATEGORIES = [
    :player,
    :menu,
    :analytics,
    :payments,
    :auth_provider,
    :broadcaster_selector,
    :push_provider,
    :ui_component,
    :login,
    :general,
  ]

  PLATFORMS = %i(ios android tvos)

  INPUT_FIELD_TYPES = %i(text checkbox textarea dropdown tags colorpicker)
end
