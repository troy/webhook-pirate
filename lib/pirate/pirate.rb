require 'json'
require 'rest_client'
require 'active_support'
  
module Pirate
  class Hook
    attr_accessor :name, :regex, :url, :method
  
    def initialize(settings)
      @name, @url, @method = settings.values_at('name', 'url', 'method')
      @regex = Regexp.new settings['regex']
  
      if @method
        @method = @method.to_sym
      else
        @method = :get
      end
    end
  
    def dispatch_if_matches(drivel)
      dispatch(drivel) if @regex.match(drivel[:message])
    end
  
    private
    def dispatch(drivel)
      if @method == :get
        if URI.parse(@url).query.present?
          req_url += "#{@url}&#{drivel.to_param}"
        else
          req_url += "#{@url}?#{drivel_to_param}"
        end
        RestClient.send @method, req_url,
          :accept => 'text/plain, text/html'
  
      elsif @method == :post
        RestClient.send @method, @url, drivel,
          :accept => 'text/plain, text/html'
      end
    end
  end
  
  class Dispatcher
    attr_accessor :hooks
  
    def initialize(hooks)
      @hooks = hooks
    end
  
    def self.new_from_json(hooks_config)
      @pirate = Dispatcher.new(JSON.parse(hooks_config).map { |c| Hook.new(c) })
    end
  
  
    def process(drivel)
      responses = []
      @hooks.each do |hook|
        response = hook.dispatch_if_matches(drivel)
        responses << response unless response.blank?
      end
  
      responses
    end
  end
end
