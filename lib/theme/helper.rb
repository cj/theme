module Theme
  module Helper
    class << self
      def setup app
        load_component_files
      end

      def load_component_files
        Dir.glob("#{Theme.config.component_path}/**/*.rb").each do |c|
          require c
        end
      end
    end

    def component name, options
      c = theme_components[name]

      if c.method(:display).parameters.length > 0
        c.display options
      else
        c.display
      end
    end
    alias :comp :component

    private

    def theme_components
      req.env[:_theme_components] ||= begin
        components = {}

        Theme.config.components.each do |name, klass|
          components[name] = Object.const_get(klass).new self
        end

        components
      end
    end
  end
end
