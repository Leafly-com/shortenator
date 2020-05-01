# Shortenator
Has this ever happened to you?
> **Manager**: We need to cut costs in our texting service! Our links are creating additional texts. How can we fix this?

*Then this is the gem for you!*

Supply the domains you'd like to be shorten and start passing your text through the Shortenator TODAY!

<small>*currently only works with bitly. no purchase necessary. apache license 2.0 terms and conditions apply*</small>

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'shortenator'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install shortenator

## Usage

### Configuration:
To configure Shortenator create `shortenator.rb` in `/config/initializers` then copy and modify the following code block to your liking:
```ruby
# in config/initializers/shortenator.rb
require 'shortenator'

Shortenator.configure do |config|
  config.domains = ['example.com'] # These are the array of domains that will be shortened if found
  config.bitly_token = ENV['BITLY_TOKEN']
  config.remove_protocol = true # OPTIONAL false by default
end
```

Setting `config.remove_protocol` to `true` will remove the `https://` from the beginning of the shortened link, saving you some more precious characters.

### Implementation:
To use Shortenator call `shorten_urls`
```ruby
def send_sms(text, number)
  shortened_links = Shortenator.shorten_urls(text)
  # more code that probably needs to happen before sending...
  TextingService.send_text(text, number)
end

send_sms('Thanks for your order, track the status here: http://example.com/orders/897987987?utm_medium=sms&utm_campaign=weekend-blowout-1234', 1234567890)
# Actual message sent: 'Thanks for your order, track the status here: bit.ly/1111aaa'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Leafly-com/shortenator.
