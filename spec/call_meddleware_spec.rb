describe 'Meddleware#call' do
  subject { Meddleware.new }

  it 'works with no block, no stack' do
    expect(subject.call).to be nil
  end

  it 'returns the blocks value' do
    res = subject.call { 123 }
    expect(res).to be 123
  end

  it 'works with args' do
    res = subject.call(:abc) { 123 }
    expect(res).to be 123
  end

  it 'passes args through to block' do
    subject.call(:abc, x: :yz) do |*args|
      expect(args).to eq [ :abc, { x: :yz } ]
    end
  end

  context 'with a middleware class' do
    let(:middleware) { double(Meddler) }

    it 'instantiates and calls the middleware' do
      expect(Meddler).to receive(:new).and_return(middleware)
      expect(middleware).to receive(:call)

      subject.use Meddler
      subject.call
    end
  end

  context 'with a middleware instance' do
    let(:middleware) { double(Meddler) }

    before do
      subject.use middleware
    end

    it 'calls middleware' do
      expect(middleware).to receive(:call)
      subject.call
    end

    it 'calls middleware with args' do
      expect(middleware).to receive(:call).with(:abc)
      subject.call(:abc)
    end

    it 'calls middleware with block' do
      expect(middleware).to receive(:call) do |&block|
        expect(block).to be_a Proc
      end

      subject.call {}
    end

    it 'calls middleware with args and block' do
      expect(middleware).to receive(:call) do |a, b, &block|
        expect(a).to be :a
        expect(b).to eq({ b: :c })
        expect(block).to be_a Proc
      end

      subject.call(:a, b: :c) {}
    end

    it 'can return a value' do
      expect(middleware).to receive(:call) { 123 }

      expect(subject.call).to be 123
    end

    context 'when middleware calls block without explicit arguments' do
      before do
        expect(middleware).to receive(:call) do |&block|
          block.call
        end
      end

      it 'implicitly passes along original arguments' do
        subject.call(:abc) do |arg|
          expect(arg).to be :abc
        end
      end
    end

    context 'when middleware calls block with explicit arguments' do
      it 'can add arguments' do
        expect(middleware).to receive(:call) do |&block|
          block.call(:abc)
        end

        subject.call do |arg|
          expect(arg).to be :abc
        end
      end

      it 'can override the arguments passed on' do
        expect(middleware).to receive(:call) do |&block|
          block.call(:abc)
        end

        subject.call(123) do |arg|
          expect(arg).to be :abc
        end
      end

      it 'can remove arguments' do
        expect(middleware).to receive(:call) do |&block|
          block.call(nil)
        end

        subject.call(:abc, :xyz) do |a, x|
          expect(a).to be nil
          expect(x).to be nil
        end
      end
    end

    context 'when middleware meddles with pass-by-ref arguments' do
      before do
        expect(middleware).to receive(:call) do |arg, &block|
          arg[:abc] = 123
          block.call
        end
      end

      it 'alters the value for the block' do
        subject.call({}) do |info|
          expect(info).to eq({ abc: 123 })
        end
      end

      it 'alters the value for the caller' do
        info = {}
        subject.call(info)
        expect(info).to eq({ abc: 123 })
      end
    end

    context 'when middleware meddles with pass-by-value arguments' do
      before do
        expect(middleware).to receive(:call) do |arg, &block|
          arg = 123
          block.call
        end
      end

      it 'has no effect...unfortunately' do
        subject.call(:abc) do |arg|
          expect(arg).to be :abc
        end
      end
    end
  end

  context 'with a middleware instance and arguments' do
    let(:middleware) { double(Meddler) }

    before do
      subject.use middleware, :abc
    end

    it 'curries the arguments' do
      expect(middleware).to receive(:call) do |*args, &block|
        expect(args).to eq([ :abc ])
      end

      subject.call
    end

    it 'curries and appends extra arguments' do
      expect(middleware).to receive(:call) do |*args, &block|
        expect(args).to eq([ :abc, :xyz ])
      end

      subject.call(:xyz)
    end
  end
end
