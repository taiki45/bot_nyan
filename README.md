# About

Bot_nyan is simple twitter-bot-framework with DSL like Sinatra.

## Installation

Add this line to your application's Gemfile:

    gem 'bot_nyan'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install bot_nyan

Or clone and build yourself:

    $ git clone git://github.com/taiki45/bot_nyan.git && cd bot_nyan

    $ gem build bot_nyan.gemspec

    $ rake install

## Usage

Simple echo and say-hello Bot.

```ruby
# bot.rb
# -*- encoding: utf-8 -*-
require 'bot_nyan'

set :consumer_key, {:key => 'XXXXXX',
                    :secret => 'XXXXXX'}
set :access_token, {:token => 'XXXXXX',
                    :secret => 'XXXXXX'}
set :name, 'my_bot_name'

on_matched_reply /^@my_bot_name\s(Hello)/u do
  reply "@#{user.screen_name} Hello!"
end

on_replied do
  reply "@#{user.screen_name} #{status.text.slice(/^@my_bot_name\s(.*)/u, 1)}"
end
```

And Simply do it.

```
$ ruby bot.rb
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
