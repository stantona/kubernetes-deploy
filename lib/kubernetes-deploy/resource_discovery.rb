# frozen_string_literal: true

require 'kubernetes-deploy/template_discovery'
module KubernetesDeploy
  class ResourceDiscovery
    def initialize(namespace:, context:, logger:, namespace_tags: [])
      @namespace = namespace
      @context = context
      @logger = logger
      @namespace_tags = namespace_tags
    end

    def crds
      @crds ||= fetch_crds.map do |cr_def|
        CustomResourceDefinition.new(namespace: @namespace, context: @context, logger: @logger,
          definition: cr_def, statsd_tags: @namespace_tags)
      end
    end

    def from_templates(template_dir, renderer)
      template_files = TemplateDiscovery.new(template_dir).templates
      resources = []
      renderer.render_files(template_files).each do |filename, definitions|
        definitions.each { |r_def| resources << build_resource(r_def, filename) }
      end
      resources
    end

    private

    def fetch_crds
      raw_json, _, st = kubectl.run("get", "CustomResourceDefinition", "-a", "--output=json", attempts: 5)
      if st.success?
        JSON.parse(raw_json)["items"]
      else
        []
      end
    end

    def kubectl
      @kubectl ||= Kubectl.new(namespace: @namespace, context: @context, logger: @logger, log_failure_by_default: true)
    end

    def build_resource(definition, filename)
      KubernetesResource.build(
        namespace: @namespace,
        context: @context,
        logger: @logger,
        definition: definition,
        statsd_tags: @namespace_tags
      )
    rescue InvalidTemplateError => e
      e.filename ||= filename
      raise e
    end
  end
end
