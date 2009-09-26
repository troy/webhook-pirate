#!/usr/bin/ruby
$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require 'sinatra'
require 'tinder'
require 'pirate'

class Hookfire
  attr_accessor :pirate

  def initialize(hooks_path)
    @pirate = Pirate::Dispatcher.new_from_json File.read(hooks_path)
  end

  def speak(message, subdomain, email_address, password, room_name, ssl = false)
    campfire = Tinder::Campfire.new subdomain, :ssl => ssl
    campfire.login email_address, password
    room = campfire.find_room_by_name room_name

    begin
      responses = @pirate.process(:message => message)
      if responses.empty?
        room.speak message
      else
        responses.each { |r| room.speak r }
      end
    rescue Exception => e
      puts "Hook dispatch failed: #{e.inspect}"
    end
  end
end


post '/speak' do
  handle_speak
end

get '/speak' do
  handle_speak
end

def handle_speak
  cfg = JSON.parse File.read(ARGV[0])

  if cfg['key'] and (params[:key] != cfg['key'])
    throw :halt, [401, "Invalid Access Key"] and return
  end

  message = params[:message]
  begin
    hookfire = Hookfire.new ARGV[1]
    hookfire.speak(message, *cfg.values_at('subdomain', 'email_address', 
                                           'password', 'room_name', 'ssl'))
  rescue Exception => e
    throw :halt, [503, "Service Unavailable"]
  end

  status 200
end
