require 'nokogiri'
require 'nokogiri-styles'
require 'tilt'

module Theme
  autoload :Version,     'theme/version'
  autoload :Component,   'theme/component'
  autoload :Assets,      'theme/assets'
  autoload :Middleware,  'theme/middleware'
  autoload :Render,      'theme/render'
  autoload :Events,      'theme/events'
  autoload :MabTemplate, 'theme/mab'

  IMAGE_TYPES   = %w(png gif jpg jpeg)
  FONT_TYPES    = %w(eot woff ttf svg)
  STATIC_TYPES  = %w(html js css map)
  VIEW_TYPES    = %w(html slim haml erb md markdown mkd mab nokogiri)
  PARTIAL_REGEX = Regexp.new '([a-zA-Z_]+)$'
  JS_ESCAPE     = { '\\' => '\\\\', '</' => '<\/', "\r\n" => '\n', "\n" => '\n', "\r" => '\n', '"' => '\\"', "'" => "\\'" }


  attr_accessor :config, :reset_config

  class NoFileFound < StandardError; end

  class << self
    def setup app = false
      if app
        load_component_files
        app.settings[:render] ||= {}
        app.plugin Assets
        if Theme.config.use_component_middleware
          app.use Middleware
        end
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
        use_component_middleware:   true,
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

      if cache.respond_to?(:render, true)
        cache.render instance, c.to_h
      else
        cache.to_s
      end
    end
  end

  def component name, options = {}, &block
    if c = theme_components[name]
      c.set_locals options
    else
      raise "No component called '#{name}' loaded."
    end
  end
  alias :comp :component

  def theme_components
    @_theme_components ||= begin
      components = {}

      Theme.config.components.each do |name, klass|
        comp_klass       = Object.const_get(klass)
        component        = comp_klass.new self
        components[name] = component
        # component.instance_variable_set :@id, name
        comp_klass.instance_variable_set :@id, name
      end

      components.each do |name, component|
        if listeners = component.class._for_listeners
          listeners.each do |id|
            if c = components[id.to_sym]
              c.add_listener component
            end
          end
        end
      end

      components
    end
  end
end
