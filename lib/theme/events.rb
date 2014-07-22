module Theme
  module Events
    def self.included(other)
      other.extend(Macros)
    end

    def add_listener(listener)
      (@listeners ||= []) << listener
    end

    def notify_listeners(event, *args)
      id = self.class.instance_variable_get :@id

      (@listeners || []).each do |listener|
        if id
          listener.trigger(:"#{id}_#{event}", *args)
        else
          listener.trigger(event, *args)
        end
      end
    end

    def trigger(name, options = {})
      callback = false

      if respond_to? name
        callback = name
      elsif self.class._event_blocks
        callback = self.class._event_blocks[name]
      end

      if callback
        if callback.is_a? Proc
          callback.call options
        else
          if method(callback).parameters.length > 0
            send callback, options
          else
            send callback
          end
        end
      end

      notify_listeners(name, options)
    end

    module Macros
      attr_accessor :_event_blocks, :_for_listeners

      def on_event(name, options = {}, &block)
        if id = options[:for]
          (@_for_listeners ||= []) << id
          name = :"#{id}_#{name}"
        end

        @_event_blocks ||= {}
        @_event_blocks[name] = options.fetch(:use) { block }

        mod = if const_defined?(:Events, false)
          const_get(:Events)
        else
          new_mod = Module.new do
            def self.to_s
              "Events(#{instance_methods(false).join(', ')})"
            end
          end
          const_set(:Events, new_mod)
        end

        include mod
      end
    end
  end
end
