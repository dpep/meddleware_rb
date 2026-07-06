Meddleware
======
![Gem](https://img.shields.io/gem/dt/meddleware?style=plastic)
[![codecov](https://codecov.io/gh/dpep/meddleware_rb/branch/main/graph/badge.svg)](https://codecov.io/gh/dpep/meddleware_rb)


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


## Ordering

Middleware can declare ordering constraints via `before:` and `after:`.  The stack is resolved with a topological sort (via Ruby's [`TSort`](https://docs.ruby-lang.org/en/master/TSort.html)), so the order is correct regardless of when each middleware is added.

```ruby
MyWidget.middleware do
  use Logger,    before: Auth
  use Validator, after:  Auth
  use Auth
end
# => [ Logger, Auth, Validator ]
```

Both kwargs accept a single class or an array.  The convenience methods `before(target, ...)` and `after(target, ...)` are shorthand for `use(..., before: target)` / `use(..., after: target)`.  A constraint referencing a middleware that isn't in the stack is treated as vacuous and ignored; circular dependencies raise `TSort::Cyclic` when the chain is built.


See the [wiki](https://github.com/dpep/meddleware_rb/wiki/DSL) for the full DSL.


## Combining chains

Two chains can be concatenated with `+`, producing a new, executable chain.  The originals are left untouched, ordering constraints are preserved, and entries from the right-hand side win on dedup.

```ruby
auth = Meddleware::Stack.new do
  use Logger
  use Auth
end

api = Meddleware::Stack.new do
  use Validator, after: Auth
end

combined = auth + api
combined.call(request) { ... }
# => [ Logger, Auth, Validator ]
```


## Thread safety

Meddleware follows the standard middleware pattern: configure once, then invoke concurrently.  `Stack#call` uses only local state, so multiple threads may execute the same chain in parallel.  Mutation methods (`use`, `prepend`, `remove`, `replace`, `clear`) are *not* safe to run concurrently with `call` or with each other, so keep configuration on a single thread at boot.

Once configuration is done, `Stack#freeze` locks the chain: it freezes the underlying entry list so any later mutation raises `FrozenError`, while `call` continues to work.

```ruby
MyWidget.middleware do
  use Auth
  use Logger
end.freeze
```


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
### Inspired by / Thanks to

[@mitchellh](https://github.com/mitchellh) + [middleware](https://github.com/mitchellh/middleware/tree/master/lib/middleware)

[@mperham](https://github.com/mperham) + [Sidekiq](https://github.com/mperham/sidekiq/blob/master/lib/sidekiq/middleware/chain.rb)

[Rails](https://github.com/rails/rails/blob/main/actionpack/lib/action_dispatch/middleware/stack.rb)
