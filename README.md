# Shortenator

Has this ever happened to you?

> **Manager**: We need to cut costs in our texting service! Our links are creating additional texts. How can we fix this?

_Then this is the gem for you!_

Supply the domains you'd like to be shorten and start passing your text through the Shortenator TODAY!

<small>_currently only works with bitly. no purchase necessary. apache license 2.0 terms and conditions apply_</small>

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
  config.remove_protocol = true # OPTIONAL false by default, this will remove the `https://` from the beginning of the shortened link.
  config.default_tags = ['repo_name'] # OPTIONAL empty by default, let you auto tag all bit.ly links for organization
  config.bitly_group_guid = ENV['DEFAULT_BITLY_GROUP_GUID'] #OPTIONAL the bitly docs recommend to set this in the event you accidently switch your token's group and hit a smaller limit than you intended. source: https://dev.bitly.com/v4/#operation/createFullBitlink
  config.caching_model = LinkLookup # OPTIONAL this allows you to save your shortened links to your own database table to avoid hitting a service's API rate limits, more details below.
  config.ignore_200_check = true # OPTIONAL false by default, this will shorten links regardless if the link throws any errors.
  config.localhost_replacement = 'website.com' # OPTIONAL 'example.com' by default, this is mainly used for testing purposes because bitly will not shorten localhost links, but if you need for whatever the reason ¯\_(ツ)_/¯
end
```

### Implementation:

To use Shortenator call `search_and_shorten_links`

```ruby
def send_sms(text, number)
  text_with_shortened_links = Shortenator.search_and_shorten_links(text)
  # more code that probably needs to happen before sending...
  TextingService.send_text(text_with_shortened_links, number)
end

send_sms('Thanks for your order, track the status here: http://example.com/orders/897987987?utm_medium=sms&utm_campaign=weekend-blowout-1234', 1234567890)
# Actual message sent: 'Thanks for your order, track the status here: bit.ly/1111aaa'
```

Need to tag certain things differently depending on the situation? You can use these params separately, or together, at runtime.

```ruby
  # Sometimes need to add additional tags for certain parts of your app? Use the `additional_tags:` param!
  Shortenator.search_and_shorten_links("text", additional_tags: ["new feature"])
```

```ruby
  # Need to over write the tags set in the configs? Use the `tags:` param!
  Shortenator.search_and_shorten_links("text", tags: ["new tag1", "new tag2"])
```

Have multiple groups that links can be shortened from? Bitly groups can set their own custom domains and can have different limits from each other while a part of the same organization. Here's how you can use different groups all around your code

```ruby
  Shortenator.search_and_shorten_links("text", bitly_group_guid: ENV['OTHER_BITLY_GROUP_GUID')
```

Need to cache your shortened links? Here's how to achieve that.
Recommended approach:

- An ActiveRecord model with a `long_link` and `short_link` as strings
- in `shortenator.rb` add to the config like so: `config.caching_model = <MODEL NAME HERE>`

Now once a link that's been shortened before attempts to be shortened, you'll save yourself a call to whatever service you use.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/Leafly-com/shortenator.
