module Theme
  class Event
    include Eventable

    event :trigger

    def trigger component_name, component_event, data = {}
      opts = Hashr.new data
      fire_event :trigger, component_name, component_event, opts
      data.clear
    end
  end
end
