require 'nokogiri'
require 'nokogiri-styles'
require 'tilt'

module Theme
  autoload :Version,    'theme/version'
  autoload :Component,  'theme/component'
  autoload :Assets,     'theme/assets'
  autoload :Middleware, 'theme/middleware'
  autoload :Render,     'theme/render'
  autoload :Event,      'theme/event'

  IMAGE_TYPES  = %w(png gif jpg jpeg)
  FONT_TYPES   = %w(eot woff ttf svg)
  STATIC_TYPES = %w(html js css map)
  VIEW_TYPES   = %w(html slim haml erb md markdown mkd mab nokogiri)

  attr_accessor :config, :reset_config

  class NoFileFound < StandardError; end

  class << self
    def setup app = false
      if app
        load_component_files
        app.plugin Assets
        app.use Middleware
      else
        yield config
      end
    end

    def config
      @config || reset_config!
    end

    def reset_config!
      @config = OpenStruct.new({
        path:             './',
        component_path:   './theme/components',
        component_url:    '/components',
        components:       {},
        view_path:        './views',
        layout:           'app',
        layout_path:      './views/layouts',
        assets: OpenStruct.new({
          js: {},
          css: {}
        }),
        asset_url:        '/assets',
        asset_path:       './assets',
        asset_js_folder:  'js',
        asset_css_folder: 'css',
        assets_compiled:  false
      })
    end

    def cache
      Thread.current[:_theme_cache] ||= OpenStruct.new({
        file: {},
        dom:  {}
      })
    end

    def load_component_files
      Dir.glob("#{Theme.config.component_path}/**/*.rb").each do |c|
        require c
      end
    end

    def load_file path, c = {}, instance = self
      cache = Theme.cache.file.fetch(path) {
        template = false

        ext = path[/\.[^.]*$/][1..-1]

        if ext && File.file?(path)
          if STATIC_TYPES.include? ext
            template = Tilt::PlainTemplate.new nil, 1, outvar: '@_output', default_encoding: 'UTF-8' do |t|
              File.read(path)
            end
          elsif FONT_TYPES.include?(ext) || IMAGE_TYPES.include?(ext)
            template = File.read path
          else
            template = Tilt.new path, 1, outvar: '@_output'
          end
        else
          VIEW_TYPES.each do |type|
            f = "#{path}.#{type}"

            if File.file? f
              template = Tilt.new f, 1, outvar: '@_output'
              break
            end
          end
        end

        unless template
          raise Theme::NoFileFound,
            "Could't find file: #{path} with any of these extensions: #{VIEW_TYPES.join(', ')}."
        end

        template
      }

      if defined? cache.render
        cache.render instance, c.to_h
      else
        cache.to_s
      end
    end
  end

  def component name, options = {}, &block
    theme_components[name].set_locals options
  end
  alias :comp :component

  def theme_event
    req.env[:_theme_event] ||= begin
      Event.new
    end
  end

  def theme_components
    req.env[:_theme_components] ||= begin
      components = {}

      Theme.config.components.each do |name, klass|
        component        = Object.const_get(klass).new self
        components[name] = component
        theme_event.register_for_event(
          event: :trigger, listener: component, callback: :trigger_event
        )
      end

      components
    end
  end
end
