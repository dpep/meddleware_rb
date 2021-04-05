Meddleware
======
A middleware framework to make meddling easy.


```ruby
require 'meddleware'

middleware = Meddlware.new do
  use Tracer
  after Tracer, Logger
end

middleware.call(args) { puts args }
```

## Usage
```
Meddleware.new
```
Create a new middleware chain.
* `block` - optional block to add middleware


```
Meddleware#call(*args, &block)
```
Execute the middleware chain.
* `args` - any arguments that should be passed through.
* `block` - a final block that should be executed and whose returned value is passed back up the chain.


```
Meddleware#use(middleware, &block)
```
Add a middleware to the chain.
* `middleware` - a class, instance, or Proc.  Must implement `.call`.
* `block` - optional block, which is either passed to the middleware constructor or used as middleware.


```
Meddleware#prepend(middleware, &block)
```
Prepend a middleware to the chain.


```
Meddleware#after(target, middleware, &block)
```
Add a middleware to the chain, after the specified target.  If the target can not be found, simply append.


```
Meddleware#before(target, middleware, &block)
```
Add a middleware to the chain, before the specified target.  If the target can not be found, simply prepend.


```
Meddleware#include?(middleware)
```
Check if middleware has been added to the chain.


```
Meddleware#count
```
Returns the chain count.


```
Meddleware#remove(middleware)
```
Remove a middleware from the chain.


```
Meddleware#replace(target, middleware)
```
Replace one middleware for another.


```
Meddleware#clear
```
Clears the chain of middleware.


```
Meddleware#empty?
```
Checks whether the chain is empty.


----
## Full Example
```ruby
# lib/mylist.rb
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

# app/initializers/mylist.rb
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

MyList.middleware do
  use OneExtra
  use Doubler

  # loggers
  prepend {|x| puts "n starts as #{x}" }
  append  {|x| puts "n ends as #{x}" }
end

# app/...
MyList.generate(2)
=> [ 2, 4, 6 ]
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


----
![Gem](https://img.shields.io/gem/dt/meddleware?style=plastic)
[![codecov](https://codecov.io/gh/dpep/meddleware_rb/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/meddleware_rb)
