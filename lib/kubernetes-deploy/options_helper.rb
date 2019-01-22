# frozen_string_literal: true

module KubernetesDeploy
  module OptionsHelper
    def self.default_and_check_template_dir(template_dir, use_stdin: false)
      if use_stdin
        if $stdin.tty?
          puts "Nothing to read from $stdin"
          exit(1)
        end

        template_dir = Dir.mktmpdir("kubernetes-deploy")
        input = $stdin.readlines.join("")
        File.open("#{File.expand_path(template_dir)}/templates.yml.erb", 'w+') { |f| f.print(input) }
        return template_dir
      end

      if !template_dir && ENV.key?("ENVIRONMENT")
        template_dir = "config/deploy/#{ENV['ENVIRONMENT']}"
      end
      if !template_dir || template_dir.empty?
        puts "Template directory is unknown. " \
          "Either specify --template-dir argument or set $ENVIRONMENT to use config/deploy/$ENVIRONMENT " \
        + "as a default path."
        exit(1)
      end

      template_dir
    end

    def self.revision_from_environment
      ENV.fetch('REVISION') do
        puts "ENV['REVISION'] is missing. Please specify the commit SHA"
        exit 1
      end
    end
  end
end
