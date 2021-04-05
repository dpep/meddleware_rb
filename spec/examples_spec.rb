module MyList
  extend self

  def middleware(&block)
    (@middleware ||= Meddleware.new).tap do
      @middleware.instance_eval(&block) if block_given?
    end
  end

  def generate(n)
    middleware.call(n) {|n| (1..n).to_a }
  end
end

class OneExtra
  def call(n)
    yield(n + 1)
  end
end

class Doubler
  def call(*)
    yield.map {|x| x * 2 }
  end
end


describe MyList do
  before do
    MyList.middleware do
      use OneExtra
      use Doubler

      # loggers
      prepend {|x| puts "n starts as #{x}" }
      append  {|x| puts "n ends as #{x}" }
    end
  end

  it 'calls middleware chain and generates a list' do
    res = nil

    expect {
      res = MyList.generate(2)
    }.to output("n starts as 2\nn ends as 3\n").to_stdout

    expect(res).to eq [ 2, 4, 6 ]
  end
end
