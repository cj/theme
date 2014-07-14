module Theme
  extend self

  autoload :Version,   'theme/version'
  autoload :Component, 'theme/component'
  autoload :Helper,    'theme/helper'
  autoload :File,      'theme/file'

  attr_accessor :config, :reset_config

  class NoFileFound < StandardError; end

  def setup
    yield config
  end

  def config
    @config || reset_config!
  end

  def reset_config!
    @config = OpenStruct.new({
      components: {}
    })
  end

  def cache
    Thread.current[:_theme_cache] ||= OpenStruct.new
  end
end
