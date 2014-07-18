require 'rack/mime'
require 'open-uri'

module Theme
  class Middleware
    attr_reader :app, :env, :res

    def initialize(app)
      @app = app
    end

    def call env
      dup.call! env
    end

    def call! env
      @env = env

      if component_path
        render_component
      else
        res
      end
    end

    private

    def res
      @res ||= begin
        if not component_path
          app.call(req.env)
        else
          Cuba::Response.new
        end
      end
    end

    def req
      @req ||= Rack::Request.new env
    end

    def component_path
      path[Regexp.new("^#{Theme.config.component_url}($|.*)")]
    end

    def path
      env['PATH_INFO']
    end

    def render_component
      app.instance_variable_set :@res, res
      app.instance_variable_set :@req, req
      app.theme_components
      app.theme_event.trigger(
        req.params['component_name'],
        req.params['component_event'],
        Hashr.new(req.params)
      )
      res.finish
    end
  end
end
