require 'meddleware/mixin'
require 'meddleware/stack'
require 'meddleware/version'

module Meddleware
  extend self
  # extend Meddleware::Stack

  # def middleware(&block)
  #   (@middleware ||= Meddleware::Stack.new).tap do
  #     @middleware.instance_eval(&block) if block_given?
  #   end
  # end

  def new(...)
    Meddleware::Stack.new(...)
  end

  def extend_object(base)
    base.extend(Meddleware::Mixin)
  end

  def append_features(base)
    base.include(Meddleware::Mixin)
  end
end
