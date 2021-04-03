Meddlware
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
