module NavigationPluginsQuestionsHelper
  module_function

  def ask_nav_items(manifest_hash)
    return manifest_hash unless manifest_hash[:type].to_s == "menu" ||  manifest_hash[:type].to_s == "nav_bar"

    booleans_array = Ask.checkbox(
      "[?] Select supported navigation items (use the spacebar for multiple)", navigation_items_mapper.values
    )

    nav_items_indices = booleans_array.each_index.select { |i| booleans_array[i] }
    manifest_hash[:supported_nav_items]  = navigation_items_mapper.keys.values_at(*nav_items_indices)
    manifest_hash
  end

  def navigation_items_mapper
    {
      nav_header: "Header",
      nav_nested_menu: "Nested Menu",
      nav_screen: "Screen",
      nav_url: "URL",
      nav_chromecast: "Chromecast",
      nav_feed: "Applicaster Social Feed",
      nav_crossmates: "Crossmates",
      nav_live: "Live Drawer",
      nav_settings: "Settings",
      nav_epg: "EPG",
    }
  end
end
