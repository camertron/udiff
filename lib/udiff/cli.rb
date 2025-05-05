# frozen_string_literal: true

module Udiff
  class HelpCmd
    HELP = <<~END
      NAME
          udiff - Diffing and patching utilities for Ruby.

      SYNOPSIS
          udiff command [command options] [arguments...]

      VERSION
          #{Udiff::VERSION}

      COMMANDS
          apply - Apply a patch.
    END

    def self.run(argv)
      new(argv).run
    end

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      if argv.empty?
        puts HELP
        0
      else
        case argv[0]
          when "apply"
            puts ApplyCmd.help
            0
          else
            puts "Unrecognized subcommand #{argv[0]}"
            1
        end
      end
    end
  end

  class ApplyCmd
    HELP = <<~END
      NAME
          apply - Apply a git diff to the current working directory.

      SYNOPSIS
          udiff apply <file>

      ARGUMENTS
          file - The patch file to apply.
    END

    def self.help
      HELP
    end

    def self.run(argv)
      new(argv).run
    end

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      patch_file = argv[0]

      unless File.exist?(patch_file)
        puts "Patch file '#{patch_file}' does not exist"
        return 1
      end

      patch_set = Udiff::PatchSet.new(File.read(patch_file))
      patch_set.files.each(&:apply)

      0
    end
  end

  class CLI
    def self.run(argv)
      new(argv).run
    end

    attr_reader :argv

    def initialize(argv)
      @argv = argv
    end

    def run
      if (cmd = subcommand)
        exit subcommand.run(argv[1..])
      end

      puts "Unrecognized subcommand"
      exit 1
    end

    private

    def subcommand
      case argv[0]
        when "-h", "help"
          HelpCmd
        when "apply"
          ApplyCmd
      end
    end
  end
end
