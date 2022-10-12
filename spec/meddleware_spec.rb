require 'singleton'

describe Meddleware do
  let(:instance) { klass.new }

  describe 'extend' do
    let(:klass) do
      Class.new do
        extend Meddleware
      end
    end

    it { expect(klass).to respond_to(:middleware) }
    it { expect(klass.middleware).to be_a Meddleware::Stack }

    it 'reuses the Meddleware instance' do
      expect(klass.middleware).to be(klass.middleware)
    end

    it 'enables DSL' do
      klass.middleware do
        use Meddler
      end

      expect(klass.middleware).to include(Meddler)
    end

    it 'supports inline usage' do
      klass.middleware.use Meddler

      expect(klass.middleware).to include(Meddler)
    end

    it 'has an instance method helper' do
      expect(instance).to respond_to(:middleware)
      expect(instance.middleware).to be(klass.middleware)
    end

    it { expect(klass).not_to respond_to(:use) }
    it { expect(instance).not_to respond_to(:use) }
  end

  describe 'include' do
    let(:klass) do
      Class.new do
        include Meddleware
      end
    end

    it { expect(instance).to respond_to(:middleware) }
    it { expect(instance.middleware).to be_a Meddleware::Stack }

    it 'reuses the Meddleware instance' do
      expect(instance.middleware).to be(instance.middleware)
    end

    it { expect(instance).not_to respond_to(:use) }
    it { expect(klass).not_to respond_to(:middleware) }
  end

  describe 'extend and include' do
    let(:klass) do
      Class.new do
        extend Meddleware
        include Meddleware
      end
    end

    it { expect(klass).to respond_to(:middleware) }
    it { expect(klass.middleware).to be_a Meddleware::Stack }

    it { expect(instance).to respond_to(:middleware) }
    it { expect(instance.middleware).to be_a Meddleware::Stack }

    it 'creates different Meddleware instances for class and instance' do
      expect(klass.middleware).not_to be(instance.middleware)
    end
  end

  describe 'include and extend' do
    let(:klass) do
      Class.new do
        include Meddleware
        extend Meddleware
      end
    end

    it { expect(klass).to respond_to(:middleware) }
    it { expect(klass.middleware).to be_a Meddleware::Stack }

    it { expect(instance).to respond_to(:middleware) }
    it { expect(instance.middleware).to be_a Meddleware::Stack }

    it 'creates different Meddleware instances for class and instance' do
      expect(klass.middleware).not_to be(instance.middleware)
    end
  end

  context "with a Module" do
    describe 'extend' do
      let(:mod) do
        Module.new do
          extend Meddleware
        end
      end

      it { expect(mod).to respond_to(:middleware) }
      it { expect(mod.middleware).to be_a Meddleware::Stack }
    end

    describe 'include' do
      let(:mod) do
        Module.new do
          include Meddleware
        end
      end

      it { expect(mod).not_to respond_to(:middleware) }
    end
  end

  context "with a Singleton" do
    describe "extend" do
      let(:klass) do
        Class.new do
          include Singleton
          extend Meddleware
        end
      end

      let(:instance) { klass.instance }

      it { expect(klass).to respond_to(:middleware) }
      it { expect(klass.middleware).to be_a Meddleware::Stack }

      it { expect(instance).to respond_to(:middleware) }
      it { expect(instance.middleware).to be(klass.middleware) }
    end
  end
end
