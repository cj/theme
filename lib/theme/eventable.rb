require "eventable"

# http://t-a-w.blogspot.com/2010/05/very-simple-parallelization-with-ruby.html
class ThreadUtility
  def self.with_connection(&block)
    begin
      yield block
    rescue Exception => e
      raise e
    ensure
      # Check the connection back in to the connection pool
      if defined? ActiveRecord
        ActiveRecord::Base.connection.close if ActiveRecord::Base.connection
      end
    end
  end
end

module Eventable
  # When the event happens the class where it happens runs this
  def fire_event(event, *return_value, &block)
    check_mutex
    threads = []

    @eventable_mutex.synchronize {

      return false unless @callbacks && @callbacks[event] && !@callbacks[event].empty?

      @callbacks[event].each do |listener_id, callbacks|
        begin
          listener = ObjectSpace._id2ref(listener_id)
          callbacks.each do |callback|
            threads << Thread.new do
              ThreadUtility.with_connection do
                listener.send callback, *return_value, &block
              end
            end
          end
        rescue RangeError => re
          # Don't bubble up a missing recycled object, I don't care if it's not there, I just won't call it
          raise re unless re.message.match(/is recycled object/)
        end
      end
    }

    threads.map(&:join)

    true
  end
end
