module Meddleware
  module Mixin
    def middleware(&block)
      (@middleware ||= Meddleware::Stack.new).tap do
        @middleware.instance_eval(&block) if block_given?
      end
    end
  end
end
