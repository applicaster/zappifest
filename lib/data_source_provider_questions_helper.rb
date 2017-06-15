module DataSourceProviderQuestionsHelper
  module_function

  def ask_data_provider_questions(manifest_hash)
    manifest_hash[:data_types] = []
    say "Data Types: \n"

    data_type_count = ask("[?] How many Data types the provider supports? ", Integer) { |q| q.in = 1..10 }

    data_type_count.times do |index|
      color "***** Data Type #{index + 1} *****", :yellow
      manifest_hash[:data_types].push(create_data_type(manifest_hash[:name]))
      color "Custom field #{index + 1} added!", :green
    end

    manifest_hash
  end

  def create_data_type(plugin_name)
    type_hash = {}

    type_hash[:label] = Question.ask_non_empty(
      "Type label: (Will be presented as #{plugin_name}_<label> in the populated dropdown in the feed manager page)",
      "label",
    )

    type_hash[:value] = Question.ask_non_empty(
      "Type value: (The expected value of the data source provider)",
      "value",
    )

    type_hash[:documentation] = {}
    type_hash[:documentation][:link] = Question.ask_non_empty(
      "Documentation link: (Link to documentation explains the structure of the data type)",
      "documentation link",
    )

    type_hash[:documentation][:input_description] = Question.ask_non_empty(
      "Input description: (A description for the expected provider input type, e.g. \"Collection URL\")",
      "documentation input description",
    )

    type_hash[:documentation][:input_placeholder] = Question.ask_non_empty(
      "Input text placeholder: (This text will be presented as placeholder text in the input field, e.g. \"Please type Collection URL\")",
      "documentation input placeholder text",
    )

    type_hash[:documentation][:input_description_image_url] = Question.ask_base("Input info screenshot URL: (Optional, Screenshot URL that provides further info for the requested input)")
    type_hash
  end
end
