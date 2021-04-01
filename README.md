Meddlware
======
For all your middleware needs

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
![Gem](https://img.shields.io/gem/dt/meddlware?style=plastic)
[![codecov](https://codecov.io/gh/dpep/meddlware_rb/branch/master/graph/badge.svg?token=1L7OD80182)](https://codecov.io/gh/dpep/meddlware_rb)
