module ReactNativeNPMQuestionsHelper
  module_function
  def ask_for_npm_dependencies(manifest_hash)
    manifest_hash[:npm_dependencies] = []
    manifest_hash[:project_dependencies] = []

    return add_npm_dependencies_android(manifest_hash) if manifest_hash[:platform] == 'android'
    add_npm_dependencies_ios(manifest_hash)
  end

  def add_npm_dependencies_ios(manifest_hash)
    manifest_hash[:npm_dependencies] = ask "[?] NPM dependencies: (e.g. module@0.38.0 or blank line to continue)" do |q|
      q.gather = ""
    end
  end

  def add_npm_dependencies_android(manifest_hash)
    add_npm_dependency = agree "[?] Would you like to add an NPM dependency? (Y/n)"

    while add_npm_dependency do
      manifest_hash[:npm_dependencies].push(ask "[?] NPM dependency name: (e.g. module@0.38.0)")

      if agree "[?] Does this dependency have a native counter part? (Y/n)"
        add_native_dependencies(manifest_hash)
      end

      add_npm_dependency = agree "[?] Would you like to add another NPM dependency? (Y/n)"
    end

  end

  def add_native_dependencies(manifest_hash)
    project_level = agree "[?] Is this dependency a project level dependency? (e.g. compile project(':SamplePlugin'))"
    return add_project_dependency(manifest_hash) if project_level
    add_dependency(manifest_hash)
  end

  def add_project_dependency(manifest_hash)
    dependency = {}
    name = Question.ask_non_whitespaces("What is the name of the project? (e.g. react-native-video)", "Project Name")
    parameters = Question.ask_base("what is the relative path of the project in the node_modules folder (e.g. node_modules/react-native-video/android)")
    dependency[name] = parameters
    manifest_hash[:project_dependencies].push(dependency)
    color "#{name} dependency added!", :green
  end

  def add_dependency(manifest_hash)
    dependency = {}
    name = Question.ask_non_whitespaces("Dependency Name:", "Dependency Name")
    parameters = Question.ask_base("Dependency Parameters: (e.g. 1.0, 4.8+, etc.)")
    dependency[name] = parameters
    manifest_hash[:extra_dependencies].push(dependency)
    color "#{name} dependency added!", :green
  end

end
