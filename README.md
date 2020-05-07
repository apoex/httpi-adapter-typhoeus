# httpi-adapter-typhoeus

[![Gem Version](https://badge.fury.io/rb/httpi-adapter-typhoeus.svg)](https://badge.fury.io/rb/httpi-adapter-typhoeus)
[![Build Status](https://travis-ci.org/apoex/httpi-adapter-typhoeus.svg?branch=master)](https://travis-ci.org/apoex/httpi-adapter-typhoeus)

httpi-adapter-typhoeus lets you use [Typhoeus](https://github.com/typhoeus/typhoeus) with [HTTPI](https://github.com/savonrb/httpi)

## Installation

Add this line to your application's Gemfile:

```ruby
gem "httpi-adapter-typhoeus"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install httpi-adapter-typhoeus

## Usage

Configure `HTTPI` to use the `Typhoeus` adapter globally:

```ruby
HTTPI.adapter = :typhoeus
```

If you're using [Savon](https://github.com/savonrb/savon) and want to configure one specific
client to use the adapter, you can initialize Savon with:

```ruby
Savon.client(adapter: :typhoeus)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/micke/httpi-adapter-typhoeus.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
