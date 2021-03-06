#!/usr/bin/ruby
$LOAD_PATH << File.dirname(__FILE__) + '/../lib'

require 'pirate'
require 'tinder'

class Sheepie
  attr_accessor :pirate

  def initialize(hooks_path)
    @pirate = Pirate::Dispatcher.new_from_json File.read(hooks_path)
  end

  def baah(subdomain, email_address, password, room_name, bot_name, ssl = false)
    campfire = Tinder::Campfire.new subdomain, :ssl => ssl
    campfire.login email_address, password

    room = campfire.find_room_by_name room_name

    #room.speak "what's the haps, peeps? also, baah."

    meant_for_me = /^#{bot_name}:\ ?/i
    room.listen do |drivel|
      if meant_for_me.match(drivel[:message])
        drivel[:message].gsub! '\u0026quot;', '"'
        drivel[:message].sub! meant_for_me, ''

        puts "Received: #{drivel[:message]}"
        begin
          responses = @pirate.process drivel
          responses.each { |r| room.speak r }
        rescue Exception => e
          puts "Hook dispatch failed: #{e.inspect}"
        end
      end
    end

    room.destroy
  end
end

cfg = JSON.parse File.read(ARGV[0])
sheepie = Sheepie.new ARGV[1]
loop do
  begin
    sheepie.baah(*cfg.values_at('subdomain', 'email_address', 'password',
                              'room_name', 'bot_name', 'ssl'))
  rescue Exception => e
    # timed out, could not connect, etc
    puts e.message
  end

  # retry delay
  sleep 10
end