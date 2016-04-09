require "csv"

class NullObject < BasicObject
  def method_missing(*)
    # NOOP
  end

  def respond_to?(*)
    true
  end

  def inspect
    "null"
  end

  klass = self
  define_method(:class) { klass }
end

class NullAttendee < NullObject
  def to_s
    ""
  end
end

class NullGame < NullObject
  def to_s
    "Unknown Game"
  end
end

class Attendee
  attr_accessor :id, :name

  def self.all
    AttendeeRepo.all.map do |r|
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

class CSVRepo
  def self.all
    CSV.readlines(source, headers: true)
  end
end

class GameRepo < CSVRepo
  def self.source
    "data/games.csv"
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

class AttendeeRepo < CSVRepo
  def self.source
    "data/attendees.csv"
  end
end
