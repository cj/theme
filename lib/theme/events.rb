module Theme
  class ThreadUtility
    def self.with_connection(&block)
      begin
        yield block
      rescue Exception => e
        raise e
      ensure
        # Check the connection back in to the connection pool
        if defined?(ActiveRecord) && ActiveRecord::Base.connection
          ActiveRecord::Base.connection.close
        end
      end
    end
  end

  module Events
    def self.included(other)
      other.extend(Macros)
    end

    def add_listener(listener)
      (@listeners ||= []) << listener
    end

    def notify_listeners(event, *args)
      id = self.class.instance_variable_get :@id
      # threads = []

      (@listeners || []).each do |listener|
        event_key  = :"for_#{id}_#{event}"
        event_keys = listener.class._event_blocks.keys

        if id && event_keys.include?(event_key)
          # threads << Thread.new do
          #   ThreadUtility.with_connection do
              listener.trigger(event_key, *args)
            # end
          # end
        end
      end
      #
      # threads.map(&:join)
    end

    def trigger(name, options = {})
      options = Hashr.new(options) if options.is_a? Hash

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
          name = :"for_#{id}_#{name}"
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
