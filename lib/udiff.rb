# frozen_string_literal: true

require_relative "udiff/version"

begin
  RUBY_VERSION =~ /(\d+\.\d+)/
  require "udiff/#{$1}/udiff"
rescue LoadError
  require "udiff/udiff"
end

module Udiff
  autoload :CLI, "udiff/cli"

  module HideImpls
    def inspect
      ["#<#{self.class.name}:0x#{(object_id * 2).to_s(16).rjust(16, '0')}"].tap do |parts|
        instance_variables.each do |ivar|
          next if ivar == :@impl || ivar.end_with?("_impl")
          parts << "#{ivar}=#{instance_variable_get(ivar).inspect}"
        end
      end.join(" ") << ">"
    end
  end

  class PatchSet
    prepend HideImpls

    def initialize(src)
      @impl = Udiff::PatchSetImpl.new(src)
    end

    def files
      @files ||= @impl.files.map do |file_impl|
        PatchedFile.new(file_impl, @impl)
      end
    end
  end

  class PatchedFile
    prepend HideImpls

    def initialize(impl, patch_set_impl)
      @impl = impl
      @patch_set_impl = patch_set_impl
    end

    def source_file
      @source_file ||= @impl.source_file(@patch_set_impl).strip
    end

    def local_source_file
      @local_source_file = source_file.delete_prefix("a#{File::SEPARATOR}")
    end

    def target_file
      @target_file ||= @impl.target_file(@patch_set_impl).strip
    end

    def local_target_file
      @local_target_file = target_file.delete_prefix("b#{File::SEPARATOR}")
    end

    def apply_s(str = nil)
      str ||= source_src
      @impl.apply(str, @patch_set_impl)
    end

    def apply
      File.write(local_source_file, apply_s)
    end

    def source_src
      File.read(local_source_file)
    end
  end
end
