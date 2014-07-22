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
      res.headers['Content-Type'] = 'Content-Type: text/javascript; charset=UTF-8'

      app.instance_variable_set :@res, res
      app.instance_variable_set :@req, req
      app.instance_variable_set :@env, req.env

      name  = req.params['component_name'].to_sym
      event = req.params['component_event'].to_sym

      app.theme_components[name].trigger event, Hashr.new(req.params)

      res.finish
    end
  end
end
