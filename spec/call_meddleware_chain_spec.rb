describe 'Meddleware#call' do
  subject { Meddleware.new }

  let(:middleware_one) { Meddler.new }
  let(:middleware_two) { Meddler.new }

  before do
    subject.use middleware_one
    subject.use middleware_two
  end

  it 'calls the whole chain' do
    expect(middleware_one).to receive(:call).and_yield
    expect(middleware_two).to receive(:call).and_yield

    expect {|b| subject.call(&b) }.to yield_control
  end

  it 'stops propagation if a middleware does not yield' do
    expect(middleware_one).to receive(:call).and_yield
    expect(middleware_two).to receive(:call)

    expect {|b| subject.call(&b) }.not_to yield_control
  end

  it 'recurses' do
    order = []

    expect(middleware_one).to receive(:call) do |&block|
      order << 1
      block.call
      order << 5
    end

    expect(middleware_two).to receive(:call) do |&block|
      order << 2
      block.call
      order << 4
    end

    subject.call { order << 3 }
    expect(order).to eq((1..5).to_a)
  end

  context 'when arguments are altered' do
    before do
      expect(middleware_one).to receive(:call) do |x, &block|
        block.call(x * 2)
      end
    end

    it 'propagates them' do
      expect(middleware_two).to receive(:call) do |x, &block|
        expect(x).to be 2
        block.call(x * 3)
      end

      subject.call(1) do |x|
        expect(x).to be 6
      end
    end

    it 'propagates them as default arguments' do
      expect(middleware_two).to receive(:call) do |x, &block|
        expect(x).to be 2
        block.call
      end

      subject.call(1) do |x|
        expect(x).to be 2
      end
    end
  end
end
