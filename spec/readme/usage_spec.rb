require 'meddleware'

# lib/mywidget.rb
class MyWidget
  extend Meddleware

  def do_the_thing
    # invoke middleware chain
    middleware.call do
      # do your thing
    end
  end
end

MyMiddleware = proc {}

# config/initializers/mywidget.rb
MyWidget.middleware do
  # add a logger
  use { puts "before the thing" }

  # add another middleware
  use MyMiddleware
end


# use it from wherever
# MyWidget.new.do_the_thing


describe MyWidget do
  it 'adds middleware to the framework' do
    expect(MyWidget.middleware).to include(MyMiddleware)
  end

  it 'calls each middleware' do
    expect(MyMiddleware).to receive(:call)

    expect {
      MyWidget.new.do_the_thing
    }.to output("before the thing\n").to_stdout
  end
end
