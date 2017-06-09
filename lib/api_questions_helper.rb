module ApiQuestionsHelper
  module_function

  def ask_for_api(manifest_hash)
    return manifest_hash if manifest_hash[:type].to_s == "data_source_provider"

    manifest_hash[:api][:require_startup_execution] = agree "[?] Plugin requires app startup execution? (Y/n)\n" +
      "By setting to true, the plugin must implement app startup interface"

    manifest_hash[:api][:class_name] = Question.ask_non_empty("Class Name:", "Class Name")
    return manifest_hash unless manifest_hash[:platform].to_s =~ /android/

    add_proguard_rules = agree "[?] Need to add custom Proguard rules? (will open a text editor)"
    if add_proguard_rules
      manifest_hash[:api][:proguard_rules] = ask_editor(nil, "vim")
    end

    manifest_hash
  end
end
