Meddleware
======
A middleware framework to make meddling easy.  Middleware is a popular pattern from Rack and Rails, which provides callers a way to execute code before and after yours.  This gives callers the ability to modify parameters or results, conditionally skip execution, and log activity without the need to monkey patch or subclass.


```ruby
require 'meddleware'

# lib/mywidget.rb
class MyWidget
  extend Meddleware

  def do_the_thing
    # invoke middleware chain
    middleware.call do
      # do your thing
      ...
    end
  end
end

# config/initializers/mywidget.rb
MyWidget.middleware do
  # add a logger
  use { puts "before the thing" }

  # add another middleware
  use MyMiddleware
end


# use it from whereever
MyWidget.new.do_the_thing
```


## Usage
Extend your class with Meddleware to add a `middleware` method.  Or use `include` to give each instance its own, individual middleware.

```ruby
class MyWidget
  extend Meddleware
end

MyWidget.middleware
```

Then wrap your class's functionality so it will get executed along with the all the registered middleware.

```ruby
class MyWidget
  extend Meddleware

  def do_the_thing
    # invoke middleware chain
    middleware.call(*args) do
      # do your thing
      ...
    end
  end
end
```


See [documentation](https://github.com/dpep/meddleware_rb/wiki/DSL) for full DSL.


----
## Full Example
```ruby
# lib/mylist.rb
module MyList
  extend Meddleware

  # generate an array from 1 to n
  def self.generate(n)
    # invoke middleware chain
    middleware.call(n) do |n|
      # do the actual work of generating your results 
      (1..n).to_a
    end
  end
end

# app/initializers/mylist.rb
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

MyList.middleware do
  use OneExtra
  use Doubler

  # loggers
  prepend {|x| puts "n starts as #{x}" }
  append  {|x| puts "n ends as #{x}" }
end


# use it
> MyList.generate(2)

# would normally output [ 1, 2 ]
# but with middleware:

n starts as 2
n ends as 3
=> [2, 4, 6]
```

----
## Contributing

Yes please  :)

1. Fork it
1. Create your feature branch (`git checkout -b my-feature`)
1. Ensure the tests pass (`bundle exec rspec`)
1. Commit your changes (`git commit -am 'awesome new feature'`)
1. Push your branch (`git push origin my-feature`)
1. Create a Pull Request


----
### Inspired by / Thanks to

[@mitchellh](https://github.com/mitchellh) + [middleware](https://github.com/mitchellh/middleware/tree/master/lib/middleware)

[@mperham](https://github.com/mperham) + [Sidekiq](https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/middleware/chain.rb)

[Rails](https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/middleware/stack.rb)


----
![Gem](https://img.shields.io/gem/dt/meddleware?style=plastic)
[![codecov](https://codecov.io/gh/dpep/meddleware_rb/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/meddleware_rb)
