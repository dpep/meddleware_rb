require 'meddleware/stack'
require 'meddleware/version'

module Meddleware
  def middleware(&block)
    (@middleware ||= Meddleware::Stack.new).tap do
      @middleware.instance_eval(&block) if block_given?
    end
  end

  private

  def self.extended(base)
    unless base.instance_methods.include?(:middleware)
      base.class_eval do
        def middleware
          self.class.middleware
        end
      end
    end
  end

  def self.append_features(base)
    # remove instance helper from `extended`
    base.remove_method(:middleware) if base.instance_methods.include?(:middleware)

    super
  end
end
