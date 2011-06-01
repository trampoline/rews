require 'rubygems'
require 'rake'

begin
  require "yard"

  YARD::Rake::YardocTask.new do |t|
    t.files = ["README.md", "lib/**/*.rb"]
  end
rescue LoadError
  desc message = %{"gem install yard" to generate documentation}
  task("yard") { abort message }
end

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings

  gem.name = "rews"
  gem.homepage = "http://github.com/trampoline/rews"
  gem.license = "MIT"
  gem.summary = %Q{a Ruby client for Exchange Web Services}
  gem.description = %Q{an email focussed Ruby client for Exchange Web Services atop Savon}
  gem.email = "craig@trampolinesystems.com"
  gem.authors = ["Trampoline Systems Ltd"]

  gem.add_runtime_dependency "savon", "= 0.9.1"
  gem.add_runtime_dependency "httpclient", ">= 2.2.0.2"
  gem.add_runtime_dependency "pyu-ntlm-http", ">= 0.1.3"
  gem.add_runtime_dependency "fetch_in", ">= 0.2.0"
  gem.add_runtime_dependency "rsxml", ">= 0.3.0"
  gem.add_runtime_dependency "nokogiri", ">= 1.4.4"
  gem.add_development_dependency "rspec", "~> 1.3.1"
  gem.add_development_dependency "rr", ">= 0.10.5"
  gem.add_development_dependency "jeweler", ">= 1.5.2"
  gem.add_development_dependency "rcov", ">= 0"
  gem.add_development_dependency "yard", ">= 0.7.1"
end
Jeweler::RubygemsDotOrgTasks.new

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :default => :spec
