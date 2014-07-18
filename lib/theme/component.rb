require 'delegate'
require 'hashr'

Hashr.raise_missing_keys = true

module Theme
  class Component < SimpleDelegator
    attr_reader :instance

    def initialize instance
      @instance = instance
      @node     = self.class.node.clone
      @name     = self.class.name

      instance.instance_variables.each do |name|
        instance_variable_set name, instance.instance_variable_get(name)
      end

      super instance
    end

    class << self
      attr_reader :html, :path, :key
      attr_accessor :node, :events

      def key name
        @key ||= begin
          Theme.config.components[name] = self.to_s
          name
        end
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

      def handle_event event, opts = {}
        @events ||= []
        @events.push [event, opts]
      end
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

    def trigger component_event, data = {}
      data           = data.to_h
      component_name = data.has_key?(:for) ? data.delete(:for) : name

      event.trigger component_name, component_event, data.to_h
      data.clear
    end

    def trigger_event component_name, component_event, data
      component_name  = component_name.to_s
      component_event = component_event.to_s

      if class_events = self.class.events
        class_events.each do |class_event, opts|
          class_event = class_event.to_s
          if class_event == component_event && (
            component_name == @name || opts[:for] == component_name
          )
            unless e = opts[:with]
              e = component_event
            end

            if method(e) && method(e).parameters.length > 0
              opts = Hashr.new data
              resp = send e, opts
            else
              resp = send e
            end

            if resp.is_a? Nokogiri::XML::Element
              res.write resp.to_html
            else
              res.write resp
            end
          end
        end
      end

      data.clear
    end
  end
end
