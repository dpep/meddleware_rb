module MyList
  # generate an array from 1 to n

  extend self

  def middleware(&block)
    (@middleware ||= Meddleware.new).tap do
      @middleware.instance_eval(&block) if block_given?
    end
  end

  def generate(n)
    # invoke middleware chain
    middleware.call(n) do |n|
      # do the actual work of generating your results
      (1..n).to_a
    end
  end
end

class OneExtra
  def call(n)
    # adds one to the argument being passed in
    yield(n + 1)
  end
end

class Doubler
  def call(*)
    # modifies the results by doubles each value
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

    allow($stdout).to receive(:puts) # suppress output
  end

  after { MyList.middleware.clear }

  it 'calls middleware chain and generates a list' do
    res = MyList.generate(2)
    expect(res).to eq [ 2, 4, 6 ]
  end

  it 'logs to stdout' do
    expect {
      MyList.generate(2)
    }.to output("n starts as 2\nn ends as 3\n").to_stdout
  end
end
