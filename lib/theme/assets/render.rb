module Theme
  module Assets
    module Render
      def self.setup app
        app.settings[:render] ||= {}
        load_engines
      end

      def view file, options = {}
        path = "#{settings[:render][:views] || Theme.config.view_path}"
        Theme.load_file "#{path}/#{file}", options, self
      end

      def render file, options = {}
        path        = "#{settings[:render][:views] || Theme.config.view_path}"
        layout_path = settings[:layout_path] || Theme.config.layout_path
        layout      = "#{layout_path}/#{settings[:render][:layout] || Theme.config.layout}"
        content     = Theme.load_file "#{path}/#{file}", options, self
        options[:content] = content
        Theme.load_file layout, options, self
      end

      def partial file, options = {}
        file.gsub! PARTIAL_REGEX, '_\1'
        path = "#{settings[:render][:views] || Theme.config.view_path}"
        Theme.load_file "#{path}/#{file}", options, self
      end

      private

      def self.load_engines
        if defined? Slim
          Slim::Engine.set_default_options \
            disable_escape: true,
            use_html_safe: true,
            disable_capture: false

          if ENV['RACK_ENV'] == 'development'
            Slim::Engine.set_default_options pretty: true
          end
        end
      end
    end
  end
end
