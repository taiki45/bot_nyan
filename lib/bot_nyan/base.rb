# -*- coding: utf-8 -*-
require 'net/https'
require 'uri'
require 'oauth'
require 'twitter'
require 'json'
require 'logger'

require "bot_nyan/version"

module BotNyan

  # For print debugs, infos, warns
  module Info
    def logger_set!(cond)
      @logger = Logger.new STDOUT
      @logger.level = cond ? Logger::DEBUG : Logger::INFO
    end

    def info(msg)
      @logger.info msg
    end

    def warn(msg)
      @logger.warn msg
    end

    def error(msg)
      @logger.error msg
    end

    def debug(msg)
      @logger.debug msg
    end
  end

  class Base
    include BotNyan::Info

    def self.run!
      self.new.run
    end

    def initialize
      logger_set! debug?
    end

    def debug?
      nil
    end

    def run
      @wrapper = set_wrapper
      info "starting bot for @#{name}"
      begin
        loop do
          begin
            @wrapper.connect do |event|
              catch :halt do
                debug event.event
                if event.text and event.text.match /(^@#{name}\s)/u
                  debug "tweet event"
                  debug event
                  match? event
                else
                  debug 'not tweets'
                  debug event
                end
              end
            end
          rescue Timeout::Error
            info "reconnectting to twitter..."
            sleep 30
          end
        end
      rescue Interrupt
        info "exitting bot service for @#{name}..."
        exit 0
      end
    end

    def set_wrapper
      Wrapper::TwitterWrapper.new name, consumer_key, access_token, debug?
    end

    def match?(event)
      get_matched_reply_actions.each do |regexp, block|
        if event.text.match regexp
          debug "matched to #{regexp}"
          instance_exec event, event.user, &block
          throw :halt
        end
      end
      if event.text.match(/(^@#{name}\s)/u) and get_relpy_action
        debug "respond to default reply"
        instance_exec event, event.user, &get_relpy_action
        throw :halt
      end
    end

    # Inner methods and called from given blocks
    def status
      @wrapper.status
    end

    def update(msg)
      @wrapper.update msg
    end

    def reply(msg)
      @wrapper.reply msg
    end

    # Inner methods that call self.class methods
    def get_matched_reply_actions
      self.class.get_matched_reply_actions
    end

    def get_relpy_action
      self.class.get_relpy_action
    end

    def add_on_replied(&block)
      @replied_action = block
    end

    class << self
      # Outer methods that called from inner of Base
      def get_matched_reply_actions
        @matched_reply_actions
      end

      def get_relpy_action
        @reply_action
      end

      # Outer methods that called from main objrct
      def on_matched_reply(regexp, &block)
        @matched_reply_actions ||= {}
        @matched_reply_actions[regexp] = block
      end

      def on_replied(&block)
        @reply_action ||= block
      end

      def set(key, value)
        keys = [:consumer_key, :access_token, :name, :debug?]
        if keys.include? key
          self.instance_eval do
            define_method key, lambda { value }
            private key
          end
        else
          raise NotImplementedError, "This option is not support, #{key}, #{value}"
        end
      end

      def set!(key, value)
        keys = [:run?]
        if keys.include? key
          define_singleton_method key, value
        else
          raise NotImplementedError, "This option is not support, #{key}, #{value}"
        end
      end
    end
  end

  # Wrapper module
  # it wrapping twitter connect or update methods
  module Wrapper
    class TwitterWrapper
      include BotNyan::Info

      def initialize(name, consumer_keys, access_tokens, cond)
        logger_set! cond
        @name = name
        unless name and consumer_keys and access_tokens
          error @name, @consumer_keys, @access_tokens
          raise RuntimeError, "Necessarys are not difined!"
        end
        @consumer = OAuth::Consumer.new(
          consumer_keys[:key],
          consumer_keys[:secret],
          :site => 'http://twitter.com'
        )
        @access_token = OAuth::AccessToken.new(
          @consumer,
          access_tokens[:token],
          access_tokens[:secret]
        )
        @client = Twitter::Client.new(
          :consumer_key => consumer_keys[:key],
          :consumer_secret => consumer_keys[:secret],
          :oauth_token => access_tokens[:token],
          :oauth_token_secret => access_tokens[:secret]
        )
        @json = nil
      end

      def connect
        uri = URI.parse("https://userstream.twitter.com/2/user.json?track=#{@name}")
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true

        https.start do |https|
          request = Net::HTTP::Post.new(uri.request_uri)
          request["User-Agent"] = "bot servise for @#{@name}"
          request.oauth!(https, @consumer, @access_token)

          buf = String.new
          https.request(request) do |response|
            raise Exception.new "Authorize failed. #{request.body}" if response.code == '401'
            response.read_body do |chunk|
              buf << chunk
              while (line = buf[/.+?(\r\n)+/m]) != nil
                begin
                  buf.sub!(line,"")
                  line.strip!
                  status = JSON.parse(line)
                rescue
                  break
                end
                @json = status
                yield status
              end
            end
          end
        end
      end

      # wrapping methods for twitter state
      def status
        @json
      end

      def update(msg)
        update_core :update, msg, @json
      end

      def reply(msg)
        update_core :reply, msg, @json
      end

      def update_core(mode, msg, json)
        i = 0
        if mode == :update
          post_text = lambda {|m| @client.update(m) }
        elsif mode == :reply
          post_text = lambda {|m| @client.update(m, :in_reply_to_status_id => json.id) }
        end
        12.times do |n|
          break if post_text.call(msg)
          sleep 0.5
          msg << " ."
          if n > 10
            @logger.warn "error to post reply to below"
            return false
          end
        end
        @logger.info "replied to #{json.id}"
        true
      end
    end
  end

  # Delegator module
  # it delegate some DSL methods to main Object
  module Delegator
    def self.delegate(*methods)
      methods.each do |method_name|
        define_method(method_name) do |*args, &block|
        return super(*args, &block) if respond_to? method_name
        Bot.send(method_name, *args, &block)
        end
        private method_name
      end
    end

    delegate :set, :on_matched_reply, :on_replied
  end
end

class Hash
  def method_missing(name, *args)
    self[name.to_s]
  end
end
