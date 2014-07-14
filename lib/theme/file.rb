module Theme
  module File
    extend self

    IMAGE_TYPES  = %w(png gif jpg jpeg)
    FONT_TYPES   = %w(eot woff ttf svg)
    STATIC_TYPES = %w(html js css map)
    VIEW_TYPES   = %w(html slim haml erb md markdown mkd mab)

    def load path, c = {}, instance = self
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
end
