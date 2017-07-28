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

  def required_with_min_length(question, field_name, min_length = 10)
    ask_base(question) do |q|
      q.validate = /.{#{min_length},}/
      q.responses[:not_valid] = "#{field_name} must have a minimum length of #{min_length}."
    end
  end
end
