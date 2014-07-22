require 'delegate'
require 'hashr'

Hashr.raise_missing_keys = true

module Theme
  class Component < SimpleDelegator
    include Theme::Events

    attr_reader :instance, :node, :name

    def initialize instance = false
      @instance = instance
      @node     = self.class.node.clone if self.class.node
      @name     = self.class.name

      instance.instance_variables.each do |name|
        instance_variable_set name, instance.instance_variable_get(name)
      end

      super instance
    end

    class << self
      attr_reader :html, :path, :id
      attr_accessor :node

      def id name
        Theme.config.components[name] = self.to_s
        @id = name
      end

      def src path
        if path[/^\./]
          @path = path
        else
          @path = "#{Theme.config.path}/#{path}"
        end

        @html = Theme.load_file @path
      end

      def dom location
        node = Theme.cache.dom.fetch(path) do
          n = Nokogiri::HTML html
          Theme.cache.dom[path] = n
        end

        if location.is_a? String
          @node = node.at location
        else
          @node = node.send location.keys.first, location.values.last
        end
      end

      def clean &block
        block.call node
      end
      alias :setup :clean
    end

    attr_accessor :node

    def method_missing method, *args, &block
      # respond_to?(symbol, include_all=false)
      if instance.respond_to? method, true
        instance.send method, *args, &block
      else
        super
      end
    end

    def node
      @node ||= self.class.node.clone
    end

    def render meth = 'display', options = {}
      if method(meth).parameters.length > 0
        opts = Hashr.new(options)
        resp = send meth, opts
      else
        resp = send meth
      end

      options.clear

      if resp.is_a? Nokogiri::XML::Element
        resp.to_html
      else
        resp
      end
    end

    def set_locals options
      options.to_h.each do |key, value|
        (class << self; self; end).send(:attr_accessor, key.to_sym)
        instance_variable_set("@#{key}", value)
      end

      self
    end
  end
end
