require_relative 'helper'

class Testing < Theme::Component
  id :testing

  on_event :test do |text|
    puts text
  end
end

class AnotherTesting
  include Theme::Events

  on_event :test, for: 'testing' do
    puts 'triggered from testing'
  end
end

scope 'events' do
  test 'listener' do
    output = Cutest.capture_output do
      testing = Testing.new
      testing.add_listener AnotherTesting.new
      testing.trigger :test, 'event for testing'
    end

    assert output['triggered from testing']
    assert output['event for testing']
  end
end
