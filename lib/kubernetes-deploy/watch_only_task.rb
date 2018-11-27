# frozen_string_literal: true

module KubernetesDeploy
  class WatchOnlyTask
    def initialize(namespace:, context:, template_dir:, bindings:, logger:, sha: '')
      @namespace = namespace
      @context = context
      @template_dir = template_dir
      @logger = logger
      @sha = sha
      @bindings = bindings
    end

    def run
      @logger.phase_heading("Initializing task")
      resources = resources_from_templates

      @logger.phase_heading("Simulating watch")
      watch_resources(resources)

      @logger.print_summary("Fake watch")
    end

    private

    def watch_resources(resources)
      watcher = ResourceWatcher.new(
        resources: resources,
        logger: @logger,
        context: @context,
        namespace: @namespace
      )
      watcher.run
    end

    def resources_from_templates
      discovery = ResourceDiscovery.new(namespace: @namespace, context: @context, logger: @logger)
      renderer = Renderer.new(current_sha: @sha, template_dir: @template_dir, logger: @logger, bindings: @bindings)
      resources = discovery.from_templates(@template_dir, renderer)
      resources.reject! do |r|
        if r.type == "Pod"
          basename = r.name.split("-")[0..-3].join("-")
          @logger.warn "Not simulating watch for #{basename} pod because its real ID cannot be determined"
        end
      end

      @logger.info("Will look for the following resources in #{@context}/#{@namespace}:")
      resources.each do |r|
        r.deploy_started_at = 5.minutes.ago # arbitrary time in the past
        @logger.info "  - #{r.id}"
      end
      resources
    end
  end
end
