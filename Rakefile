require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "rews"
    gem.summary = %Q{a Ruby client for Exchange Web Services}
    gem.description = %Q{an email focussed Ruby client for Exchange Web Services atop Savon}
    gem.email = "craig@trampolinesystems.com"
    gem.homepage = "http://github.com/trampoline/rews"
    gem.authors = ["Trampoline Systems Ltd"]
    gem.add_dependency "savon", ">= 0.8.6"
    gem.add_dependency "ntlm-http", ">= 0.1.2"
    gem.add_dependency "fetch_in", ">= 0.2.0"
    gem.add_runtime_dependency "rsxml", ">= 0.1.4"
    gem.add_development_dependency "httpclient", ">= 2.1.7"
    gem.add_development_dependency "rspec", ">= 1.2.9"
    gem.add_development_dependency "rr", ">= 0.10.5"
    gem.add_development_dependency "nokogiri", ">= 1.4.4"

    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

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

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "rews #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
