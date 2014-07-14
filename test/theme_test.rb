require_relative 'helper'

setup do
  Theme.reset_config!
  Theme.setup do |c|
    c.component_path = './test/dummy/components'
    c.components = {
      header: 'HeaderComponent'
    }
  end

  Cuba.reset!
  Cuba.plugin Theme::Helper
end

scope 'theme' do
  test 'component' do

  end
end
