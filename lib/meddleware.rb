require 'meddleware/version'

class Meddleware
  def initialize(&block)
    instance_eval(&block) if block_given?
  end

  def use(klass, *args)
    remove(klass)
    stack << Entry.new(klass, args)
    self
  end
  alias append use

  def prepend(klass, *args)
    remove(klass)
    stack.insert(0, Entry.new(klass, args))
    self
  end

  def after(after_klass, klass, *args)
    remove(klass)
    i = index(after_klass) || count - 1
    stack.insert(i + 1, Entry.new(klass, args))
    self
  end

  def before(before_klass, klass, *args)
    remove(klass)
    i = index(before_klass) || 0
    stack.insert(i, Entry.new(klass, args))
    self
  end

  def remove(klass)
    stack.reject! { |entry| entry.klass == klass }
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

  def call(*args, &block)
    chain = to_a
    traverse = proc do |*updated_args|
      args = updated_args unless updated_args.empty?
      if chain.empty?
        yield(*args) if block
      else
        chain.shift.call(*args, &traverse)
      end
    end
    traverse.call(*args)
  end

  def to_a
    stack.map &:build
  end

  private

  def stack
    @stack ||= []
  end

  def index(klass)
    stack.index {|entry| entry.klass == klass }
  end

  Entry = Struct.new(:klass, :args) do
    def build
      case klass
      when Class
        unless klass.method_defined?(:call)
          raise ArgumentError, "middleware must respond to `.call`: #{klass}"
        end

        klass.new(*args)
      else
        # instance or Proc?
        unless klass.respond_to?(:call)
          raise ArgumentError, "middleware must respond to `.call`: #{klass}"
        end

        if args.empty?
          klass
        else
          # curry args
          proc {|more_args| klass.call(*args, *more_args) }
        end
      end
    end
  end
end
