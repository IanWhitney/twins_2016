require "rubygems"
require "bundler/setup"
require "thor"
require_relative "lib/twins"

class Twins < Thor
  desc "attendees", "lists all attendees"
  def attendees
    Attendee.all.each {|x| puts "#{x}"}
  end

  desc "games", "Lists all games, or for a specific attendee"
  option :unattended
  option :attended_by, type: :string
  def games(attendee_id: nil)
    if options[:attended_by]
      attendee = Attendee.for(id: options[:attended_by])
      Game.attended_by(attendee: attendee)
    else
      Game.all
    end.each {|x| puts "#{x}"}
  end

  desc "attend ATTENDEE_ID GAME_ID", "Assigns game to that attendee"
  def attend(attendee_id, game_id)
    attendee = Attendee.for(id: attendee_id)
    game = Game.for(id: game_id)
    game.attended_by!(attendee: attendee)
  end
end

Twins.start(ARGV)
