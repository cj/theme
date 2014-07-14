module Theme
  class Component

    class << self
      def src file
        puts 'src file for component'
      end

      def dom location
        puts 'dom location for component'
      end

      def clean &block
        puts 'block of code to clean dom element'
      end
    end
  end
end
