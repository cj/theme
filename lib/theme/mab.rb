require 'mab'

def mab(&blk)
  Mab::Builder.new({}, self, &blk).to_s
end

module Theme
  class MabTemplate < Tilt::Template
    def self.builder_class
      @builder_class ||= Class.new(Mab::Builder) do
        def __capture_mab_tilt__(&block)
          __run_mab_tilt__ do
            text capture(&block)
          end
        end
      end
    end

    def prepare
    end

    def evaluate(scope, locals, &block)
      builder = self.class.builder_class.new({}, scope)

      locals.each do |local, value|
        (class << builder; self end).send(:define_method, local, Proc.new { value })
      end

      if data.kind_of? Proc
        (class << builder; self end).send(:define_method, :__run_mab_tilt__, &data)
      else
        builder.instance_eval <<-CODE, __FILE__, __LINE__
          def __run_mab_tilt__
            capture(&Proc.new {#{data}})
          end
        CODE
      end

      if block
        builder.__capture_mab_tilt__(&block)
      else
        builder.__run_mab_tilt__
      end

      builder
    end
  end
end

Tilt.register Theme::MabTemplate, 'mab'
