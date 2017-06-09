module ReactNativeQuestionsHelper
  module_function

  def ask_for_react_native(manifest_hash)
    manifest_hash[:react_native] = agree "[?] React Native plugin? (Y/n)"
    return manifest_hash unless manifest_hash[:react_native]
    manifest_hash[:extra_dependencies] = []

    extra_dependencies_count = ask("[?] Number of extra dependencies: ", Integer) { |q| q.in = 0..10 }

    extra_dependencies_count.times do |index|
      dependency = {}
      color "***** Dependency #{index + 1} *****", :yellow

      name = Question.ask_non_whitespaces("Dependency Name:", "Dependency Name")
      description = manifest_hash[:platform] == :android ? "e.g. 1.0, 4.8+, etc." : "e.g. ~> 1.0, >= 3.0, :path => 'path/to/dependency', etc."
      parameters = Question.ask_base("Dependency Parameters: (#{description})")
      dependency[name] = parameters
      manifest_hash[:extra_dependencies].push(dependency)
      color "#{name} dependency added!", :green
    end

    manifest_hash[:npm_dependencies] = ask "[?] NPM dependencies: (e.g. module@0.38.0 or blank line to continue)" do |q|
      q.gather = ""
    end

    if manifest_hash[:platform].to_s =~ /android/
      manifest_hash[:api][:react_packages] = ask "[?] React Packages: (or blank line to quit)" do |q|
        q.gather = ""
      end
    end

    manifest_hash
  end
end
