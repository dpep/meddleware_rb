require 'meddleware/version'

class Meddleware
  def initialize(&block)
    instance_eval(&block) if block_given?
  end

  def use(*args, **kwargs, &block)
    entry = create_entry(args, kwargs, block)
    remove(entry[0])
    stack << entry
    self
  end
  alias append use

  def prepend(*args, **kwargs, &block)
    entry = create_entry(args, kwargs, block)
    remove(entry[0])
    stack.insert(0, entry)
    self
  end

  def after(after_klass, *args, **kwargs, &block)
    entry = create_entry(args, kwargs, block)
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

  def before(before_klass, *args, **kwargs, &block)
    entry = create_entry(args, kwargs, block)
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

  def include?(*klass)
    klass.all? {|x| index(x) }
  end

  def remove(*klass)
    stack.reject! { |entry| klass.include?(entry[0]) }
    self
  end

  def replace(old_klass, *args, **kwargs, &block)
    entry = create_entry(args, kwargs, block)
    remove(entry[0])

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

  def index(klass)
    stack.index {|entry| entry[0] == klass }
  end

  def create_entry(args, kwargs, block)
    klass, *args = args

    if [ klass, block ].compact.empty?
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
    stack.map do |klass, args, kwargs, block|
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

  if RUBY_VERSION < '3'
    require 'meddleware/v2_7'
    prepend Meddleware::V2_7
  end
end
