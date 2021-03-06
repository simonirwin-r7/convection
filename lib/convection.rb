##
# Root module
##
module Convection
  class << self
    def template(*args, &block)
      Model::Template.new(*args, &block)
    end

    def stack(*args)
      Control::Stack.new(*args)
    end
  end
end

require_relative 'convection/version'
require_relative 'convection/model/attributes'
require_relative 'convection/model/template'
require_relative 'convection/control/stack'
