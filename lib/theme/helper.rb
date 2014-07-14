module Theme
  module Helper
    class << self
      def setup app
        load_components
      end

      def load_components
        Dir.glob("#{Theme.config.component_path}/**/*.rb").each do |c|
          require c
        end
      end
    end
  end
end
