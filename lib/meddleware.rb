require 'meddleware/version'

class Meddleware
  include Enumerable

  def initialize
    instance_eval(&block) if block_given?
  end

  def each(&block)
    stack.each(&block)
  end

  def index(klass)
    stack.index {|entry| entry.klass == klass }
  end

  def remove(klass)
    stack.reject! { |entry| entry.klass == klass }
  end

  def use(klass, *args)
    remove(klass)
    stack << Entry.new(klass, args)
  end
  alias append use

  def prepend(klass, *args)
    remove(klass)
    stack.insert(0, Entry.new(klass, args))
  end

  def after(after_klass, klass, *args)
    remove(klass)
    i = index(after_klass) || count - 1
    stack.insert(i + 1, Entry.new(klass, args))
  end

  def before(before_klass, klass, *args)
    remove(klass)
    i = index(before_klass) || 0
    stack.insert(i, Entry.new(klass, args))
  end

  def empty?
    stack.empty?
  end

  def clear
    stack.clear
  end

  def call(*args, &block)
    chain = map(&:build)
    traverse = proc do |*updated_args|
      args = updated_args unless updated_args.empty?
      if chain.empty?
        yield *args
      else
        chain.shift.call(*args, &traverse)
      end
    end
    traverse.call(*args)
  end

  private

  def stack
    @stack ||= []
  end

  Entry = Struct.new(:klass, :args) do
    def build
      klass.new(*args)
    end
  end
end
