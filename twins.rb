require "rubygems"
require "bundler/setup"
require "thor"
require "csv"

class Attendee
  attr_accessor :id, :name

  def self.all
    CSV.readlines("data/attendees.csv", headers: true).map do |r|
      new(id: r["id"], name: r["name"])
    end
  end

  def self.for(id:)
    all.detect(->{NullAttendee.new}) { |x| x.id == id }
  end

  def initialize(id:, name:)
    self.id = id
    self.name = name
  end

  def to_s
    "#{name} (#{id})"
  end
end

class NullAttendee
  def id
    "<null>"
  end

  def name
    "<null>"
  end

  def to_s
    "Not Picked"
  end
end

class Game
  attr_accessor :id, :opponent, :attendee
  attr_reader :date

  def self.all
    GameRepo.all.map do |g|
      attendee = Attendee.for(id: g["attendee_id"])
      new(id: g["id"], date: g["date"], opponent: g["opponent"], attendee: attendee)
    end
  end

  def self.attended_by(attendee:)
    all.select {|g| g.attendee.id == attendee.id}
  end

  def self.for(id:)
    all.detect(->{NullGame.new}) { |x| x.id == id }
  end

  def attended_by!(attendee:)
    GameRepo.add_attendee(game: self, attendee: attendee)
  end

  def initialize(id:, date:, opponent: , attendee:)
    self.id = id
    self.date = date
    self.opponent = opponent
    self.attendee = attendee
  end

  def date=(x)
    @date = x
  end

  def to_s
    "#{id}: #{opponent}: #{date} -- #{attendee}"
  end
end

class NullGame
  def id
    "<null>"
  end

  def date
    "<null>"
  end

  def opponent
    "<null>"
  end

  def attendee
    "<null>"
  end


  def to_s
    "Unknown Game"
  end
end

class GameRepo
  def self.all
    CSV.readlines("data/games.csv", headers: true)
  end

  def self.add_attendee(game:, attendee:)
    CSV.open("data/ngames.csv", 'w', headers: true) do |csv|
      csv.puts ["id","opponent","date","attendee_id"]
      all.each do |g|
        if g["id"].to_i == game.id.to_i
          g["attendee_id"] = attendee.id
        end
        csv.puts g
      end
    end
    `cp data/ngames.csv data/games.csv`
  end
end

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
