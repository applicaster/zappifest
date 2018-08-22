module CustomFieldsQuestionsHelper
  module_function

  def ask_for_custom_fields(manifest_hash)
    manifest_hash[:custom_configuration_fields] = []
    say "Custom configuration fields: \n"

    add_assets_bundle = agree "[?] Does the plugin require bundled assets "\
      "(This will create file uploader field for users to upload an assets zip file, "\
      "and will add the assets to resources of the bundle on build time)"

    add_assets_bundle_field(manifest_hash) if add_assets_bundle
    add_custom_fields = agree "[?] Wanna add custom fields? "
    return unless add_custom_fields

    custom_fields_count = ask("[?] How many? ", Integer) { |q| q.in = 1..10 }

    custom_fields_count.times do |index|
      color "***** Custom field #{index + 1} *****", :yellow
      manifest_hash[:custom_configuration_fields].push(create_custom_field)
      color "Custom field #{index + 1} added!", :green
    end

    manifest_hash
  end

  def create_custom_field
    field_hash = {}

    input_type_index = Ask.list "[?] Input field type", ManifestHelpers::INPUT_FIELD_TYPES
    field_hash[:type] = ManifestHelpers::INPUT_FIELD_TYPES[input_type_index]

    field_hash[:key] = Question.ask_non_whitespaces("What is the key for this field?", "Custom key")
    tooltip_type_selection = Question.multiple_option_question(
      "[?] What type of tooltip would you like to display for this field",
      ManifestHelpers::TOOLTIP_TYPES.map{ |t| t[:value] }
    )

    tooltip_type = ManifestHelpers::TOOLTIP_TYPES[tooltip_type_selection][:type]

    field_hash[:tooltip_text] =
      case tooltip_type
      when :plain
        Question.required_with_min_length("Enter the tooltip text to be displayed in the Zapp UI", "Tooltip text", 10)
      when :url
        url = Question.required_with_url_validation("Enter the URL to be displayed", "Tooltip URL")
        "To learn about this field, click <a href=#{url} target=_blank>here</a>."
      when :mixed
        text = Question.ask_base("Enter the tooltip text to be displayed in the Zapp UI")
        url = Question.required_with_url_validation("Enter the URL to be displayed", "Tooltip URL")
        "#{text}. \nTo learn more about it, click <a href=#{url} target=_blank>here</a>."
      end

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

    field_hash
  end

  def add_assets_bundle_field(manifest_hash)
    if manifest_hash[:platform]
      manifest_hash[:custom_configuration_fields].push(
        send("#{manifest_hash[:platform].downcase}_assets_bundle_field"),
      )
    else
      manifest_hash[:custom_configuration_fields].push(ios_assets_bundle_field)
      manifest_hash[:custom_configuration_fields].push(android_assets_bundle_field)
    end
  end

  def android_assets_bundle_field
    {
      type: "uploader",
      key: "android_assets_bundle",
      tooltip_text: assets_bundle_tooltip
    }
  end

  def ios_assets_bundle_field
    {
      type: "uploader",
      key: "ios_assets_bundle",
      tooltip_text: assets_bundle_tooltip
    }
  end

  def assets_bundle_tooltip
    "Upload a Zip file following the folder structure and hierarchy guideline of the "\
      "platform. The Zip file will be extracted during the build time and will add the assets to "\
      "the resources of the bundle/package. This field does not affect runtime and a change will "\
      "require a new build of the app version."
  end
end
