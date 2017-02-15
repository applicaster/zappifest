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
    ask("[?] #{question} ")
  end
end
