describe Meddleware::Mixin do
  let(:instance) { klass.new }

  describe 'extend' do
    let(:klass) do
      Class.new do
        extend Meddleware::Mixin
      end
    end

    it { expect(klass).to respond_to(:middleware) }
    it { expect(klass.middleware).to be_a Meddleware }

    it 'reuses the Meddleware instance' do
      expect(klass.middleware).to be(klass.middleware)
    end

    it 'enables DSL' do
      helper = ->(*) {}

      klass.middleware do
        use helper
      end

      expect(klass.middleware).to include(helper)
    end

    it { expect(klass).not_to respond_to(:use) }
    it { expect(instance).not_to respond_to(:middleware) }
    it { expect(instance).not_to respond_to(:use) }
  end

  describe 'include' do
    let(:klass) do
      Class.new do
        include Meddleware::Mixin
      end
    end

    it { expect(instance).to respond_to(:middleware) }
    it { expect(instance.middleware).to be_a Meddleware }

    it 'reuses the Meddleware instance' do
      expect(instance.middleware).to be(instance.middleware)
    end

    it { expect(klass).not_to respond_to(:middleware) }
  end

  describe 'extend and include' do
    let(:klass) do
      Class.new do
        extend Meddleware::Mixin
        include Meddleware::Mixin
      end
    end

    it { expect(klass).to respond_to(:middleware) }
    it { expect(klass.middleware).to be_a Meddleware }

    it { expect(instance).to respond_to(:middleware) }
    it { expect(instance.middleware).to be_a Meddleware }

    it 'creates different Meddleware instances for class and instance' do
      expect(klass.middleware).not_to be(instance.middleware)
    end
  end
end
