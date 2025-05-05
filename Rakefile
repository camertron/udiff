# frozen_string_literal: true

require "rake/testtask"
require "rake/extensiontask"
require "rb_sys/version"
require "rb_sys/toolchain_info"

SOURCE_PATTERN = "*.{rs,toml,lock,rb}"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/**/test_*.rb"]
end

Rake::ExtensionTask.new("udiff") do |ext|
  ext.lib_dir = "lib/udiff"
  ext.source_pattern = SOURCE_PATTERN
  ext.cross_compile = true
  ext.cross_platform = RbSys::ToolchainInfo.supported_ruby_platforms
  ext.config_script = ENV["ALTERNATE_CONFIG_SCRIPT"] || "extconf.rb"
end

task default: :test
