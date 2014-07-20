class HeaderComponent < Theme::Component
  id :header
  src 'test/dummy/index.html'
  dom 'body > .body > header'
  clean do
    node.css('.sf-menu > li').each_with_index do |li, i|
      if i != 0
        li.remove
        li.css('ul').remove
      else
        li.at('a').inner_html  = ''
        li.at('ul').inner_html = ''
      end
    end
  end

  on_event :test, for: 'some_component', use: 'some_component_test'

  attr_reader :menu, :node_li, :node_ul

  def display
    @node_li  = node.at('.sf-menu > li').remove
    @node_ul  = node_li.at('ul').remove
    node_menu = node.at('.sf-menu')

    add_menus @menu, node_menu

    node
  end

  private

  def some_component_test
    res.write 'this is from the header component'
  end

  def add_menus menu, node_menu
    menu.each do |name, data|
      data         = data.to_h
      li           = node_li
      a            = li.at('a')
      a.inner_html = name
      a['href']    = data[:href] if data.key? :href

      node_menu.add_child li

      if links = data[:links]
        node_menu.add_child node_ul

        add_menus links, node_menu.at('ul')
      end
    end
  end

  def node_li
    @node_li.dup
  end

  def node_ul
    @node_ul.dup
  end
end
