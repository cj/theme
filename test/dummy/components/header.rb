class HeaderComponent < Theme::Component
  src './test/dummy/index.html'
  dom 'body > .body > header'
  clean do |node|
    # clean the header dom node
  end
end

