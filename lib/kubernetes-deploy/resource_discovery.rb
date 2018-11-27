# frozen_string_literal: true

module KubernetesDeploy
  class ResourceDiscovery
    include KubeclientBuilder

    def initialize(namespace:, context:, logger:, namespace_tags:)
      @namespace = namespace
      @context = context
      @logger = logger
      @namespace_tags = namespace_tags
    end

    def crds
      @crds ||= begin
        raw = JSON.parse(crd_client.get_custom_resource_definitions(as: :raw))
        raw["items"].map do |r_def|
          CustomResourceDefinition.new(namespace: @namespace, context: @context, logger: @logger,
            definition: r_def, statsd_tags: @namespace_tags)
        end
      end
    end

    private

    def crd_client
      @crd_client ||= build_apiextensions_v1beta1_kubeclient(@context)
    end
  end
end
