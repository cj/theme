require 'rack/mime'
require 'open-uri'

module Theme
  module Assets
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

        if assets_path
          render_assets
        else
          res
        end
      end

      private

      def res
        @res ||= begin
          if not assets_path
            app.call(req.env)
          else
            Cuba::Response.new
          end
        end
      end

      def req
        @req ||= Rack::Request.new env
      end

      def assets_path
        path[Regexp.new("^#{Theme.config.asset_url}($|.*)")]
      end

      def path
        env['PATH_INFO']
      end

      def type
        if matched = path.match(/(?<=#{Theme.config.asset_url}\/).*(?=\/)/)
          matched[0]
        else
          ''
        end
      end

      def name
        @name ||= begin
          cleaned = path.gsub(/\.#{ext}$/, '')
          cleaned = cleaned.gsub(/^#{Theme.config.asset_url}\//, '')
          cleaned = cleaned.gsub(/^#{type}\//, '')
          cleaned
        end
      end

      def ext
        if matched = path.match(/(?<=\.).*$/)
          matched[0]
        else
          false
        end
      end

      def render_assets
        case type
        when 'css', 'stylesheet', 'stylesheets'
          content_type = 'text/css; charset=utf-8'
        when 'js', 'javascript', 'javascripts'
          content_type = 'text/javascript; charset=utf-8'
        else
          content_type = Rack::Mime.mime_type ".#{ext}"
        end

        res.headers.merge!({
          "Content-Type"              => content_type,
          "Cache-Control"             => 'public, max-age=2592000, no-transform',
          'Connection'                => 'keep-alive',
          'Age'                       => '25637',
          'Strict-Transport-Security' => 'max-age=31536000',
          'Content-Disposition'       => 'inline'
        })

        if name == "all-#{sha}"
          @name = 'dominate-compiled'
          res.write render_single_file
        elsif name == 'all'
          res.write render_all_files
        else
          res.write render_single_file
        end

        res.finish
      end

      def render_all_files
        content = ''
        files   = Theme.config.assets[ext]
        path    = "#{Theme.config.asset_path}/#{type}"

        files.each do |file|
          if file[/^http/]
            content += open(file).string
          else
            content += Theme.load_file("#{path}/#{file}")
          end
        end

        content
      end

      def render_single_file
        path  = "#{Theme.config.asset_path}/#{type}"
        Theme.load_file "#{path}/#{name}.#{ext}"
      end

      def sha
        Thread.current[:_sha] ||= (Theme.config.sha || `git rev-parse HEAD`.strip)
      end
    end
  end
end
