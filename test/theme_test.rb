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
  Cuba.plugin Theme
  Cuba.define do
    on 'header' do
      menu = {
        'Home' => {
          href: '/',
          links: {
            'Sub Menu' => { href: '/sub_menu' }
          }
        },
        'Test' => { href: '/test' }
      }

      res.write component(:header, menu: menu).render
    end
  end
end

scope 'theme' do
  test 'component' do
    _, _, resp = Cuba.call({
      'PATH_INFO'      => '/header',
      'SCRIPT_NAME'    => '/header',
      'REQUEST_METHOD' => 'GET',
      'rack.input'     => {}
    })
    body = resp.join

    assert body[/Home/]
    assert body[/Test/]
    assert body[/\/test/]
    assert body[/Sub Menu/]
    assert body[/\/sub_menu/]
  end

  test 'events' do
    _, _, resp = Cuba.call({
      'PATH_INFO'   => '/components',
      'SCRIPT_NAME'   => '/components',
      'REQUEST_METHOD' => 'GET',
      'rack.input'     => {},
      'QUERY_STRING'   => 'component_name=some_component&component_event=test'
    })
    body = resp.join

    assert body['this is from the header component']
  end
end
