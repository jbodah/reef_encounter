class OpenSeaBoard
end

class Player
  def self.available_colors
    %i{green purple red yellow}
  end

  def initialize(color)
    @shrimp = 4.times.map { Shrimp.new(color) }
  end
end

class Shrimp
  attr_reader :color

  def initialize(color)
    @color = color
  end
end

class AlgaCylinder
  def self.available_colors
    %i{blue green purple red}
  end

  attr_reader :color

  def initialize(color)
    @color = color
  end
end

class LarvaCube
  def self.available_colors
    %i{grey orange pink white yellow}
  end

  def self.initial_distribution
    10.times.map { available_colors.map { |c| new(c) } }
  end

  attr_reader :color

  def initialize(color)
    @color = color
  end
end

class PolypTile
  def self.available_colors
    %i{grey orange pink white yellow}
  end

  def self.initial_distribution
    40.times.flat_map { available_colors { |c| new(c) } }
  end
end

class CoralTile
  def self.initial_distribution
    # todo setup instances, coin flip and initialize board setup
  end
end

class ParrotFish
end

class CoralReefBoard
  def initialize
    @coral_tiles = CoralTile.initialize_tiles
  end
end

class PlayerScreen
end

class TurnActionCard
end

class Game
  def initialize(number_of_players)
    @coral_reef_board = CoralReefBoard.new
    @players = Player.available_colors.first(number_of_players).map do |c|
      Player.new(c)
    end
  end
end

game = Game.new
game.prepare
game.start
