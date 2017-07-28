module CustomFieldsQuestionsHelper
  module_function

  def ask_for_custom_fields(manifest_hash)
    manifest_hash[:custom_configuration_fields] = []
    say "Custom configuration fields: \n"
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
    field_hash[:tooltip_text] = Question
      .required_with_min_length("Enter a text the UI tooltip in Zapp", "Tooltip text", 10)

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
end
