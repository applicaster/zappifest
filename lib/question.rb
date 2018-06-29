module Question
  module_function

  def ask_non_empty(question, field_name)
    ask("[?] #{question} ") do |q|
      q.validate = /^(?!\s*$).+/
      q.responses[:not_valid] = "#{field_name} cannot be blank."
    end
  end

  def ask_non_whitespaces(question, field_name)
    ask("[?] #{question} ") do |q|
      q.validate = /^[\S]+$/
      q.responses[:not_valid] = "#{field_name} cannot be blank or contains whitespaces."
    end
  end

  def ask_base(question)
    ask("[?] #{question}") do |q|
      yield(q) if block_given?
    end
  end

  def ask_for_version(question, validate_presence = true, default = nil)
    ask_base(question) do |q|
      q.validate = lambda do |version|
        valid_version = version if version.present?
        validate_presence ? valid_version?(valid_version || default) : true
      end
      q.responses[:not_valid] = "Version not valid"
      q.default = default
    end
  end

  def valid_version?(version)
    return if version.nil?
    return Versionomy.parse(version)
  rescue Versionomy::Errors::VersionomyError
    false
  end

  def multiple_option_question(question, answer_options)
    Ask.list(question, answer_options)
  end

  def required_with_min_length(question, field_name, min_length = 10)
    ask_base(question) do |q|
      q.validate = /.{#{min_length},}/
      q.responses[:not_valid] = "#{field_name} must have a minimum length of #{min_length}."
    end
  end

  def required_with_url_validation(question, field_name)
    ask_base(question) do |q|
      q.validate = /^(http|https):\/\/|[a-z0-9]+([\-\.]{1}[a-z0-9]+)*\.[a-z]{2,5}(:[0-9]{1,5})?(\/.*)?$/
      q.responses[:not_valid] = "#{field_name} must be a valid URL. (i.e http://www.a-domain.com/some-resource)"
    end
  end
end
