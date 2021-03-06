module Theme
  module Assets
    autoload :Middleware, 'theme/assets/middleware'
    autoload :Render,     'theme/assets/render'

    class << self
      def setup app
        app.plugin Render
        app.use Middleware
        Tilt.register Theme::MabTemplate, 'mab'
      end

      def css_assets options = {}
        options = {
          'data-turbolinks-track' => 'true',
          rel: 'stylesheet',
          type: 'text/css',
          media: 'all'
        }.merge options

        url = Theme.config.asset_url

        if Theme.config.assets_compiled
          options[:href] = "#{url}/css/theme-compiled-#{sha}.css"
        else
          options[:href] = "#{url}/css/theme.css"
        end

        Theme.mab { link options }
      end

      def js_assets options = {}
        options = {
          'data-turbolinks-track' => 'true',
        }.merge options

        url = Theme.config.asset_url

        if Theme.config.assets_compiled
          options[:src] = "#{url}/js/theme-compiled-#{sha}.js"
        else
          options[:src] = "#{url}/js/theme.js"
        end

        Theme.mab { script options }
      end

      def compile
        Theme.config.assets.to_h.each do |type, assets|
          content = ''

          if assets.length > 0
            type_path = "#{Theme.config.asset_path}/#{Theme.config[:"asset_#{type}_folder"]}"
            assets.each do |file|
              path = "#{type_path}/#{file}"
              content += Theme.load_file path
            end
            tmp_path = "#{type_path}/tmp.theme-compiled.#{type}"
            File.write tmp_path, content
            system "minify #{tmp_path} > #{type_path}/theme-compiled-#{sha}.#{type}"
            File.delete tmp_path
          end
        end
      end

      def sha
        Thread.current[:_sha] ||= (Theme.config.sha || `git rev-parse HEAD`.strip)
      end
    end

    def css_assets options = {}
      Theme::Assets.css_assets options
    end

    def js_assets options = {}
      Theme::Assets.js_assets options
    end

    private

    def sha
      self.class.sha
    end
  end
end
