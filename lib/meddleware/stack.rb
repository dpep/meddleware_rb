require 'tsort'

module Meddleware
  class Stack
    def initialize(&block)
      instance_eval(&block) if block_given?
    end

    def use(*args, **kwargs, &block)
      entry = create_entry(args, kwargs, block)
      remove(entry[0], clear_constraints: false)
      stack << entry
      self
    end
    alias append use

    def prepend(*args, **kwargs, &block)
      entry = create_entry(args, kwargs, block)
      remove(entry[0], clear_constraints: false)
      stack.insert(0, entry)
      self
    end

    def after(after_klass, *args, **kwargs, &block)
      entry = create_entry(args, kwargs, block)
      remove(entry[0], clear_constraints: true, clear_as_target: false)

      i = if after_klass.is_a? Array
        after_klass.map { |x| index(x) }.compact.max
      else
        index(after_klass)
      end
      i ||= count - 1 # last element

      stack.insert(i + 1, entry)
      add_ordering_constraints(after_klass, entry[0], :after)
      self
    end

    def before(before_klass, *args, **kwargs, &block)
      entry = create_entry(args, kwargs, block)
      remove(entry[0], clear_constraints: true, clear_as_target: false)

      i = if before_klass.is_a? Array
        before_klass.map { |x| index(x) }.compact.min
      else
        index(before_klass)
      end
      i ||= 0 # first element

      stack.insert(i, entry)
      add_ordering_constraints(before_klass, entry[0], :before)
      self
    end

    def include?(*klass)
      klass.all? { |x| index(x) }
    end

    def remove(*klass, clear_constraints: true, clear_as_target: true)
      stack.reject! { |entry| klass.include?(entry[0]) }

      if clear_constraints
        constraints.reject! do |source, target|
          klass.include?(source) || (clear_as_target && klass.include?(target))
        end
      end

      self
    end

    def replace(old_klass, *args, **kwargs, &block)
      entry = create_entry(args, kwargs, block)
      remove(entry[0], clear_constraints: true, clear_as_target: false)

      i = index(old_klass)

      unless i
        raise RuntimeError, "middleware not present: #{old_klass}"
      end

      stack.delete_at(i)
      constraints.map! do |source, target|
        source = entry[0] if source == old_klass
        target = entry[0] if target == old_klass
        [ source, target ]
      end
      stack.insert(i, entry)
      self
    end

    def count
      stack.count
    end
    alias size count

    def clear
      stack.clear
      constraints.clear
    end

    def empty?
      stack.empty?
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

    def stack
      @stack ||= []
    end

    def constraints
      @constraints ||= []
    end

    def index(klass)
      sorted_stack.index { |entry| entry[0] == klass }
    end

    def create_entry(args, kwargs, block)
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

        [ klass, args, kwargs, block ].compact
      else
        [ block ]
      end
    end

    def build_chain
      # build the middleware stack
      sorted_stack.map do |klass, args, kwargs, block|
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

    def sorted_stack
      entries_by_key = stack.each_with_object({}) { |entry, hash| hash[entry[0]] = entry }
      keys = entries_by_key.keys
      deps = keys.each_with_object({}) { |key, hash| hash[key] = [] }

      constraints.each do |before_key, after_key|
        next unless entries_by_key.key?(before_key) && entries_by_key.key?(after_key)

        deps[after_key] << before_key
      end

      sorter = Object.new
      sorter.extend(TSort)
      sorter.define_singleton_method(:tsort_each_node) { |&blk| keys.each(&blk) }
      sorter.define_singleton_method(:tsort_each_child) { |node, &blk| deps[node].each(&blk) }
      sorter.tsort # validates there are no cycles

      dependents = keys.each_with_object({}) { |key, hash| hash[key] = [] }
      indegree = keys.each_with_object({}) { |key, hash| hash[key] = deps[key].count }

      deps.each do |node, prerequisites|
        prerequisites.each do |prerequisite|
          dependents[prerequisite] << node
        end
      end

      queue = keys.select { |key| indegree[key].zero? }
      sorted_keys = []

      until queue.empty?
        node = queue.shift
        sorted_keys << node

        dependents[node].each do |dependent|
          indegree[dependent] -= 1
          next unless indegree[dependent].zero?

          insert_at = queue.index { |candidate| keys.index(candidate) > keys.index(dependent) } || queue.length
          queue.insert(insert_at, dependent)
        end
      end

      sorted_keys.map { |key| entries_by_key[key] }
    end

    def add_ordering_constraints(targets, middleware, position)
      Array(targets).compact.each do |target|
        pair = position == :before ? [ middleware, target ] : [ target, middleware ]
        constraints << pair unless constraints.include?(pair)
      end
    end
  end
end
