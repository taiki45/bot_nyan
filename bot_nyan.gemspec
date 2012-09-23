# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'bot_nyan/version'

Gem::Specification.new do |gem|
  gem.name          = "bot_nyan"
  gem.version       = BotNyan::VERSION
  gem.authors       = ["Taiki ONO"]
  gem.email         = ["taiks.4559@gmail.com"]
  gem.description   = %q{Bot_nyan is quickly creating twitter-bot in Ruby with Sinatra like DSL}
  gem.summary       = %q{Classy twitter-bot-framework in a DSL}
  gem.homepage      = "http://taiki45.github.com/bot_nyan"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'oauth', "~>0.4.7"
  gem.add_dependency 'twitter', "~>3.7.0"
end
