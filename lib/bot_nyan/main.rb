# -*- coding: utf-8 -*-

require 'bot_nyan/base'
require 'optparse'

module BotNyan
  class Bot < Base
    set! :run?, lambda { __FILE__ == $0 }
    if ARGV.any?
      OptionParser.new do |op|
        op.on('-d', 'set the debug print is on') { set :debug?, true }
      end.parse!(ARGV.dup)
    end
  end
  at_exit { BotNyan::Bot.run! if $!.nil? }
end

extend BotNyan::Delegator
