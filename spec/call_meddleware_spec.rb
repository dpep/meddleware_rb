describe 'Meddleware#call' do
  subject { Meddleware.new }

  let(:middleware) { Meddler.new }
  ruby3 = RUBY_VERSION >= '3'

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
    subject.call(:abc, x: :yz) do |*args, **kwargs|
      expect(args).to eq [ :abc ]
      expect(kwargs).to eq x: :yz
    end
  end

  context 'with a middleware class' do
    it 'instantiates and calls the middleware' do
      expect(Meddler).to receive(:new).and_return(middleware)
      expect(middleware).to receive(:call)

      subject.use Meddler
      subject.call
    end
  end

  context 'with a middleware instance' do
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

    it 'calls middleware with args, kwargs, and block' do
      expect(middleware).to receive(:call) do |a, b:, &block|
        expect(a).to be :a
        expect(b).to eq(:c)
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
        subject.call(:abc, x: :yz) do |*args, **kwargs|
          expect(args).to eq [ :abc ]
          expect(kwargs).to eq x: :yz
        end
      end
    end

    context 'when middleware calls block with explicit arguments' do
      it 'can add arguments' do
        expect(middleware).to receive(:call) do |&block|
          block.call(:abc, x: :yz)
        end

        subject.call do |*args, **kwargs|
          expect(args).to eq [ :abc ]
          expect(kwargs).to eq x: :yz
        end
      end

      it 'can override the arguments passed on' do
        expect(middleware).to receive(:call) do |&block|
          block.call(:abc, x: :z)
        end

        subject.call(123, x: :y) do |*args, **kwargs|
          expect(args).to eq [ :abc ]
          expect(kwargs).to eq x: :z
        end
      end

      it 'can remove arguments' do
        expect(middleware).to receive(:call) do |&block|
          block.call(nil)
        end

        subject.call(:abc, x: :yz) do |arg, **kwargs|
          expect(arg).to be nil
          expect(kwargs).to be_empty
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
          expect {
            expect(arg).to be 123
          }.to fail
        end
      end
    end
  end

  context 'with a middleware instance and arguments' do
    before do
      subject.use middleware, :abc, x: :yz
    end

    it 'curries the arguments' do
      expect(middleware).to receive(:call) do |*args, **kwargs, &block|
        expect(args).to eq [ :abc ]
        expect(kwargs).to eq x: :yz
      end

      subject.call
    end

    it 'curries and appends extra arguments', if: ruby3 do
      expect(middleware).to receive(:call) do |*args, **kwargs, &block|
        expect(args).to eq [ :abc, :def ]
        expect(kwargs).to eq x: :yz, y: :z
      end

      subject.call(:def, y: :z)
    end

    it 'curries and appends, without yielding implicitly' do
      res = subject.call(:xyz) { 123 }
      expect(res).to be nil
      end

    it 'curries and appends, and can yield explicitly' do
      expect(middleware).to receive(:call) do |*args, &block|
        block.call
      end

      res = subject.call(:xyz) { 123 }
      expect(res).to be 123
    end
  end

  context 'with a middleware Proc' do
    it 'passes arguments to the Proc' do
      fn = proc {|arg| expect(arg).to be :abc }
      expect(fn).to receive(:call).and_call_original

      subject.use fn
      subject.call(:abc)
    end

    it 'curries arguments' do
      fn = proc {|*args| expect(args).to eq [ :xyz, :abc ] }
      expect(fn).to receive(:call).and_call_original

      subject.use fn, :xyz
      subject.call(:abc)
    end

    it 'can alter arguments' do
      fn = proc {|data| data[:abc] = 123 }
      subject.use fn

      data = {}
      subject.call(data)
      expect(data).to eq({ abc: 123 })
    end

    it 'can not abort middleware chain...unfortunately' do
      fn = proc { return }

      subject.use fn
      expect {
        subject.call
      }.to raise_error(LocalJumpError)
    end

    it 'calls yield implicitly' do
      fn = proc {}
      expect(fn).to receive(:call).and_call_original

      subject.use fn
      res = subject.call { 123 }
      expect(res).to be 123
    end
  end

  context 'with a middleware Lambda' do
    it 'does not explicitly call yield' do
      fn = ->{}
      expect(fn).to receive(:call).and_call_original

      subject.use fn
      res = subject.call { 123 }
      expect(res).to be nil
    end

    it 'does can explicitly yield' do
      fn = ->(&block) { block.call }
      expect(fn).to receive(:call).and_call_original

      subject.use fn
      res = subject.call { 123 }
      expect(res).to be 123
    end
  end
end
