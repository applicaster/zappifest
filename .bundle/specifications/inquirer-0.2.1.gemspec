# -*- encoding: utf-8 -*-
# stub: inquirer 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "inquirer".freeze
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dominik Richter".freeze]
  s.date = "2015-05-26"
  s.description = "Interactive user prompts on CLI for ruby.".freeze
  s.email = "dominik.richter@googlemail.com".freeze
  s.homepage = "https://github.com/arlimus/inquirer.rb".freeze
  s.licenses = ["Apache v2".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Interactive user prompts on CLI for ruby.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<term-ansicolor>.freeze, [">= 1.2.2"])
    else
      s.add_dependency(%q<term-ansicolor>.freeze, [">= 1.2.2"])
    end
  else
    s.add_dependency(%q<term-ansicolor>.freeze, [">= 1.2.2"])
  end
end
