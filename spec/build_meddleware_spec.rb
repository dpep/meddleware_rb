A = Class.new(Meddler)
B = Class.new(Meddler)
C = Class.new(Meddler)


describe Meddleware do
  subject { described_class.new }

  def stack
    subject.send(:build_chain).map &:class
  end

  shared_examples 'a middleware adder method' do |name|
    let(:function) do
      subject.method(name).yield_self do |fn|
        if fn.arity < -1
          # needs prefix arg, eg. :before/:after
          proc {|*args, &block| fn.call(nil, *args, &block) }
        else
          fn
        end
      end
    end

    it 'adds middleware to the stack' do
      function.call(A)
      expect(stack).to eq [ A ]
    end

    it 'does not add duplicates' do
      3.times { function.call(A) }
      expect(stack).to eq [ A ]
    end

    it 'returns self' do
      expect(function.call(A)).to be subject
    end

    it 'is idempotent' do
      subject.use A
      function.call(B)
      res = stack

      function.call(B)
      expect(stack).to eq res
    end

    context 'with arguments' do
      after { subject.send :build_chain }

      it 'accepts an argument' do
        expect(A).to receive(:new).with(:abc)
        function.call(A, :abc)
      end

      it 'accepts multiple arguments' do
        expect(A).to receive(:new).with(:abc, :xyz)
        function.call(A, :abc, :xyz)
      end

      it 'accepts kwargs' do
        expect(A).to receive(:new).with(a: 1, b: 2)
        function.call(A, a: 1, b: 2)
      end

      it 'works with all forms of kwargs' do
        expect(A).to receive(:new).with(a: 1, b: 2)
        function.call(A, { a: 1, b: 2 })

        expect(B).to receive(:new).with({ a: 1, b: 2 })
        function.call(B, { a: 1, b: 2 })

        expect(C).to receive(:new).with({ a: 1, b: 2 })
        function.call(C, a: 1, b: 2)
      end

      it 'works with both args and kwargs' do
        expect(A).to receive(:new).with(:abc, a: 1, b: 2)
        function.call(A, :abc, a: 1, b: 2)
      end
    end

    context 'when middleware is an instance' do
      it 'adds middleware to the stack' do
        function.call(A.new)
        expect(stack).to eq [ A ]
      end

      it 'will add multiple instances of the same class' do
        function.call(A.new)
        function.call(A.new)
        expect(stack).to eq [ A, A ]
      end
    end

    context 'when middleware is a block' do
      it 'accepts procs' do
        function.call(Proc.new {})
        expect(stack).to eq [ Proc ]
      end

      it 'accepts lambdas' do
        function.call(-> {})
        expect(stack).to eq [ Proc ]
      end

      it 'accepts inline blocks' do
        function.call {}
        expect(stack).to eq [ Proc ]
      end
    end

    context 'when middleware is invalid' do
      it 'rejects classes that do not implement `.call`' do
        expect {
          function.call(Class.new)
        }.to raise_error(ArgumentError)
      end

      it 'rejects instances that do not respond to `.call`' do
        expect {
          function.call(123)
        }.to raise_error(ArgumentError)
      end

      it 'fails when both instance and block are passed' do
        expect {
          function.call(A.new) {}
        }.to raise_error(ArgumentError)
      end

      it 'rejects nil' do
        expect {
          function.call(nil)
        }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#use' do
    it_behaves_like 'a middleware adder method', :use

    it 'appends middleware in order' do
      subject.use A
      subject.use B
      expect(stack).to eq [ A, B ]
    end

    it 'reorders duplicates' do
      subject.use A
      subject.use B
      subject.use A
      expect(stack).to eq [ B, A ]
    end
  end

  describe '#prepend' do
    it_behaves_like 'a middleware adder method', :prepend

    it 'prepends middleware in order' do
      subject.prepend A
      subject.prepend B
      expect(stack).to eq [ B, A ]
    end

    it 'reorders duplicates' do
      subject.prepend A
      subject.prepend B
      subject.prepend A
      expect(stack).to eq [ A, B ]
    end
  end

  describe '#after' do
    it_behaves_like 'a middleware adder method', :after

    it 'adds middleware where specified' do
      subject.use A
      subject.use B
      subject.after A, C
      expect(stack).to eq [ A, C, B ]
    end

    it 'maintans order for duplicates' do
      subject.use A
      subject.use B
      subject.after A, C
      subject.after A, C
      expect(stack).to eq [ A, C, B ]
    end

    it 'works when target is missing' do
      subject.use A
      subject.after B, C
      expect(stack).to eq [ A, C ]
    end

    it 'works when target is nil' do
      subject.use A
      subject.after nil, C
      expect(stack).to eq [ A, C ]
    end
  end

  describe '#before' do
    it_behaves_like 'a middleware adder method', :before

    it 'adds middleware where specified' do
      subject.use A
      subject.use B
      subject.before B, C
      expect(stack).to eq [ A, C, B ]
    end

    it 'maintans order for duplicates' do
      subject.use A
      subject.use B
      subject.before B, C
      subject.before B, C
      expect(stack).to eq [ A, C, B ]
    end

    it 'works when target is missing' do
      subject.use A
      subject.before B, C
      expect(stack).to eq [ C, A ]
    end

    it 'works when target is nil' do
      subject.use A
      subject.before nil, C
      expect(stack).to eq [ C, A ]
    end
  end

  describe '#empty?' do
    it 'works with empty middleware' do
      expect(subject).to be_empty
      expect(subject.empty?).to be true
      expect(stack.empty?).to be true
    end

    it 'works with middleware' do
      subject.use A
      expect(subject).not_to be_empty
      expect(subject.empty?).to be false
      expect(stack.empty?).to be false
    end
  end

  describe '#clear' do
    it 'works' do
      subject.use A
      subject.clear
      expect(subject).to be_empty
    end

    it 'works with an empty stack' do
      subject.clear
      expect(subject).to be_empty
    end
  end

  describe '#count' do
    it 'works' do
      expect(subject.count).to be 0

      subject.use A
      expect(subject.count).to be 1

      subject.use B
      expect(subject.count).to be 2

      subject.remove B
      expect(subject.count).to be 1
    end
  end

  describe '#include?' do
    it 'works' do
      expect(subject.include?(A)).to be false

      subject.use A
      expect(subject.include?(A)).to be true
    end
  end

  describe '#remove' do
    before do
      subject.use A
      subject.use B
      subject.use C
      expect(stack).to eq [ A, B, C ]
    end

    it 'removes middleware' do
      subject.remove(B)
      expect(stack).to eq [ A, C ]
      subject.remove(A)
      expect(stack).to eq [ C ]
      subject.remove(C)
      expect(subject).to be_empty
    end

    it 'is idempotent' do
      3.times { subject.remove(A) }
      expect(stack).to eq [ B, C ]
    end

    it 'works with nil' do
      subject.remove(nil)
      expect(stack).to eq [ A, B, C ]
    end
  end

  describe '#replace' do
    before do
      subject.use A
      subject.use B

      expect(stack).to eq [ A, B ]
    end

    it 'replaces middleware' do
      subject.replace(A, C)
      expect(stack).to eq [ C, B ]
    end

    it 'works with middleware instances' do
      instance = A.new
      subject.replace(A, instance)

      expect(subject).to include instance
      expect(subject).not_to include A

      subject.replace(instance, B)
      expect(stack).to eq [ B ]
    end

    it 'fails when target middleware is missing' do
      expect {
        subject.replace(C, C)
      }.to raise_error(RuntimeError)
    end

    it 'fails when middleware is invalid' do
      expect {
        subject.replace(A, nil)
      }.to raise_error(ArgumentError)
    end
  end

  describe '.new' do
    it 'supports block mode' do
      instance = described_class.new do
        use A
        prepend B
      end

      expect(instance).to include A
      expect(instance).to include B
    end
  end

  describe '#index' do
    before do
      subject.use A
      subject.use B
    end

    it do
      expect(subject.send(:index, A)).to be 0
      expect(subject.send(:index, B)).to be 1
      expect(subject.send(:index, C)).to be nil
      expect(subject.send(:index, nil)).to be nil
    end

    it 'is a private method' do
      expect {
        subject.index
      }.to raise_error(NoMethodError, /private/)
    end
  end
end
