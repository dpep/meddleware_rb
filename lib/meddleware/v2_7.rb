# backwards compatible functionality for Ruby 2.5

class Meddleware
  module V2_7
    def use(*klass_and_args, &block)
      entry = create_entry(klass_and_args, block)
      remove(entry[0])
      stack << entry
      self
    end
    alias append use

    def prepend(*klass_and_args, &block)
      entry = create_entry(klass_and_args, block)
      remove(entry[0])
      stack.insert(0, entry)
      self
    end

    def after(after_klass, *klass_and_args, &block)
      entry = create_entry(klass_and_args, block)
      remove(entry[0])

      i = if after_klass.is_a? Array
        after_klass.map {|x| index(x) }.compact.max
      else
        index(after_klass)
      end
      i ||= count - 1 # last element

      stack.insert(i + 1, entry)
      self
    end

    def before(before_klass, *klass_and_args, &block)
      entry = create_entry(klass_and_args, block)
      remove(entry[0])

      i = if before_klass.is_a? Array
        before_klass.map {|x| index(x) }.compact.min
      else
        index(before_klass)
      end
      i ||= 0 # first element

      stack.insert(i, entry)
      self
    end

    def replace(old_klass, *klass_and_args, &block)
      entry = create_entry(klass_and_args, block)
      remove(entry[0])

      i = index(old_klass)

      unless i
        raise RuntimeError, "middleware not present: #{old_klass}"
      end

      stack[i] = entry
      self
    end

    def call(*args)
      chain = build_chain
      default_args = args

      traverse = proc do |*args|
        if args.empty?
          args = default_args
        else
          default_args = args
        end

        if chain.empty?
          yield(*args) if block_given?
        else
          middleware = chain.shift

          if middleware.is_a?(Proc) && !middleware.lambda?
            middleware.call(*args)

            # implicit yield
            traverse.call(*args)
          else
            middleware.call(*args, &traverse)
          end
        end
      end
      traverse.call(*args)
    end


    private

    def create_entry(klass_and_args, block)
      klass, *args = klass_and_args

      if [ klass, block ].compact.count == 0
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

        [ klass, args, block ].compact
      else
        [ block ]
      end
    end

    def build_chain
      # build the middleware stack
      stack.map do |klass, args, block|
        if klass.is_a? Class
          klass.new(*args, &block)
        else
          if args.nil? || args.empty?
            klass
          else
            # curry args
            ->(*more_args, &block) do
              klass.call(*args, *more_args, &block)
            end
          end
        end
      end
    end
  end
end
