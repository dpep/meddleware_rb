require 'tsort'

module Meddleware
  class Stack
    include TSort

    Entry = Struct.new(:klass, :args, :kwargs, :block, :before, :after)

    def initialize(&block)
      @stack = []
      instance_eval(&block) if block_given?
    end

    def freeze
      @stack.freeze
      super
    end

    def use(*args, before: nil, after: nil, **kwargs, &block)
      entry = create_entry(args, kwargs, block, before: before, after: after)
      remove(entry.klass)
      stack << entry
      self
    end
    alias append use

    def prepend(*args, before: nil, after: nil, **kwargs, &block)
      entry = create_entry(args, kwargs, block, before: before, after: after)
      remove(entry.klass)
      stack.unshift(entry)
      self
    end

    def after(after_klass, *args, **kwargs, &block)
      use(*args, **kwargs, after: after_klass, &block)
    end

    def before(before_klass, *args, **kwargs, &block)
      use(*args, **kwargs, before: before_klass, &block)
    end

    def include?(*klass)
      klass.all? {|x| index(x) }
    end

    def remove(*klass)
      stack.reject! { |entry| klass.include?(entry.klass) }
      self
    end

    def replace(old_klass, *args, before: nil, after: nil, **kwargs, &block)
      entry = create_entry(args, kwargs, block, before: before, after: after)
      remove(entry.klass) unless entry.klass == old_klass

      i = index(old_klass)

      unless i
        raise RuntimeError, "middleware not present: #{old_klass}"
      end

      stack[i] = entry
      self
    end

    def count
      stack.count
    end
    alias size count

    def clear
      stack.clear
    end

    def empty?
      stack.empty?
    end

    def +(other)
      unless other.is_a?(Meddleware::Stack)
        raise ArgumentError, "expected Meddleware::Stack, got #{other.class}"
      end

      self.class.new.tap do |result|
        (stack + other.stack).each do |entry|
          result.stack.reject! { |e| e.klass == entry.klass }
          result.stack << entry
        end
      end
    end

    def call(*args, **kwargs)
      chain = build_chain
      default_args = args
      default_kwargs = kwargs

      traverse = proc do |*args, **kwargs|
        if args.empty? && kwargs.empty?
          args = default_args
          kwargs = default_kwargs
        else
          default_args = args
          default_kwargs = kwargs
        end

        if chain.empty?
          yield(*args, **kwargs) if block_given?
        else
          middleware = chain.shift

          if middleware.is_a?(Proc) && !middleware.lambda?
            middleware.call(*args, **kwargs)

            # implicit yield
            traverse.call(*args, **kwargs)
          else
            middleware.call(*args, **kwargs, &traverse)
          end
        end
      end

      traverse.call(*args, **kwargs)
    end


    protected

    attr_reader :stack

    def index(klass)
      stack.index {|entry| entry.klass == klass }
    end

    # TSort: iterate over all entries
    def tsort_each_node(&block)
      stack.each(&block)
    end

    # TSort: yield entries that must come BEFORE the given entry
    def tsort_each_child(entry, &block)
      after_targets = Array(entry.after).compact
      stack.each do |other|
        next if other.equal?(entry)
        other_before = Array(other.before).compact

        if after_targets.include?(other.klass) || other_before.include?(entry.klass)
          yield other
        end
      end
    end

    def create_entry(args, kwargs, block, before: nil, after: nil)
      klass, *args = args

      if [ klass, block ].none?
        raise ArgumentError, 'either a middleware or block must be provided'
      end

      if klass
        # validate
        if klass.is_a? Class
          unless klass.method_defined?(:call)
            raise ArgumentError, "middleware must implement `.call`: #{klass}"
          end
        else
          unless klass.respond_to?(:call)
            raise ArgumentError, "middleware must respond to `.call`: #{klass}"
          end

          unless block.nil?
            raise ArgumentError, 'can not supply middleware instance and block'
          end
        end

        Entry.new(klass, args, kwargs, block, before, after)
      else
        Entry.new(block, nil, nil, nil, before, after)
      end
    end

    def build_chain
      # build the middleware stack, resolving dependencies via TSort
      tsort.map do |entry|
        klass = entry.klass
        args = entry.args
        kwargs = entry.kwargs
        block = entry.block

        if klass.is_a? Class
          klass.new(*args, **kwargs, &block)
        else
          if args.nil? && kwargs.nil?
            # middleware is a block
            klass
          elsif args.empty? && kwargs.empty?
            # nothing to curry, just pass through middleware instance
            klass
          else
            # curry args
            ->(*more_args, **more_kwargs, &block) do
              klass.call(
                *(args + more_args),
                **kwargs.merge(more_kwargs),
                &block
              )
            end
          end
        end
      end
    end
  end
end
