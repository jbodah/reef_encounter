require 'reef_encounter/version'

module ReefEncounter
  class OpenSeaBoard
    attr_reader :coral_tiles

    def initialize
      @coral_tiles = CoralTile.initial_distribution
    end
  end

  class Player
    def self.available_colors
      %i{green purple red yellow}
    end

    attr_reader :color, :shrimp, :parrot_fish, :player_screen

    def initialize(color)
      @color = color
      @shrimp = 4.times.map { Shrimp.new(color) }
      @parrot_fish = ParrotFish.new(color)
      @player_screen = PlayerScreen.new(color)
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
      40.times.flat_map { available_colors.map { |c| new(c) } }
    end

    attr_reader :color

    def initialize(color)
      @color = color
    end
  end

  class CoralTile
    def self.initial_distribution
      [
        %i{white yellow green blue},
        %i{white orange red purple},
        %i{pink white pink green},
        %i{pink grey green pink},
        %i{grey white red purple},
        %i{grey yellow blue red},
        %i{yellow orange blue red},
        %i{yellow pink pink blue},
        %i{orange grey blue green},
        %i{orange pink green red}
      ].map { |args| new(*args) }
    end

    # Params should match the starfish side of the tile
    def initialize(first_coral, second_coral, first_alga, second_alga)
      @first_coral = first_coral
      @second_coral = second_coral
      @first_alga = first_alga
      @second_alga = second_alga
      @flipped = false
    end

    # Helper to see which corals the tile manages
    def corals
      @corals ||= [@first_coral, @second_coral].sort
    end

    def flip!
      @flipped = !@flipped
    end

    def stronger_coral
      @flipped ? @second_coral : @first_coral
    end

    def weaker_coral
      !@flipped ? @second_coral : @first_coral
    end

    def showing_alga
      @flipped ? @second_alga : @first_alga
    end

    def background_alga
      !@flipped ? @second_alga : @first_alga
    end
  end

  class ParrotFish
    def initialize(color)
      @color = color
    end
  end

  class CoralReefBoard
    class Board
      def initialize(position_rows)
        @position_rows = position_rows
      end

      def each_position
        Enumerator.new do |yielder|
          @position_rows.each do |position_row|
            position_row.each do |position|
              yielder.yield position
            end
          end
        end
      end
    end

    class Position
      attr_accessor :tile
      attr_reader :initial_state, :starting_space_color

      def initialize(ascii_char)
        @original_ascii_char = ascii_char
        @initial_state = determine_initial_state
      end

      private

      def determine_initial_state
        case @original_ascii_char
        when 'x'
          :unplayable
        when '.'
          :normal_space
        when 'G','P','Y','O','W'
          @starting_space_color = parse_color(@original_ascii_char)
          :starting_space
        else
          raise "Unexpected position character #{ascii_char}"
        end
      end

      def parse_color(c)
        case c
        when 'G' then :grey
        when 'P' then :pink
        when 'Y' then :yellow
        when 'W' then :white
        when 'O' then :orange
        else
          raise 'Unexpected color'
        end
      end
    end

    def self.starting_boards
      [
        "
          .xxx..
          xxxxxx
          x.GxYx
          xOxxx.
          xx.xPx
          xxxWxx
          .xxx..
        ",
        "
          xxxx..
          xxGxx.
          xPx.x.
          x.x.Yx
          xOxWxx
          xx.xxx
          xxxx..
        ",
        "
          ..xxx.
          xxxWxx
          xx.xPx
          xGxxxx
          .xYxOx
          .xx.xx
          .xxxx.
        ",
        "
          ..xx..
          xxxxxx
          xPxWxx
          xxx.x.
          .GxxOx
          xx.Yxx
          xxxx.x
        "
      ].map { |layout| new(layout) }
    end

    # @param layout - ASCII board layout
    #   x = land
    #   . = open space
    #   B/P/Y/O/W = starting space for colors
    def initialize(layout)
      @board = parse(layout)
    end

    def count_tiles
      @board.each_position.reduce(0) do |count, p| 
        count += 1 if !p.tile.nil?
        count
      end
    end

    def add_starting_tiles(tiles)
      # TODO more optimization
      @board.each_position.reduce(tiles) do |remaining, p|
        if p.initial_state == :starting_space
          tile = remaining.delete_if {|t| t.color == p.starting_space_color}
          raise unless tile
          p.tile = tile
        end
        remaining
      end
    end

    #def print
      #puts @layout
    #end

    private

    # @param layout - ASCII board layout
    #   x = land
    #   . = open space
    #   B/P/Y/O/W = starting space for colors
    def parse(layout)
      position_rows = layout.strip.each_line.map do |line|
        line.strip.each_char.map do |char|
          Position.new(char)
        end
      end
      @board = Board.new(position_rows)
    end
  end

  class PlayerScreen
    def initialize(color)
      @color = color
    end
  end

  #class TurnActionCard
  #end

  class TileBag
    def initialize(tiles)
      @tiles = tiles.shuffle
    end

    def size
      @tiles.size
    end

    def empty?
      size == 0
    end

    def draw
      raise "Can't draw! Tile Bag is empty!" if empty?
      @tiles.pop
    end

    # TODO could be optimized
    def draw_colors(*colors)
      colors.map { |c| draw_color(c) }
    end

    def draw_color(color)
      rejects = []
      tile = draw
      until tile.color == color
        rejects << tile
        tile = draw
      end
      replace(*rejects)
      tile
    end

    def replace(*tiles)
      @tiles += tiles
      @tiles.shuffle!
    end
  end

  class Game
    attr_reader :players, :coral_reef_boards, :open_sea_board, :tile_bag

    def initialize(num_players)
      @players = Player.available_colors.first(num_players).map do |c|
        Player.new(c)
      end
      @tile_bag = TileBag.new(PolypTile.initial_distribution)
      @coral_reef_boards = CoralReefBoard.starting_boards.shuffle.first(num_players)
      @open_sea_board = OpenSeaBoard.new
    end

    def prepare
      tile_colors = PolypTile.available_colors
      @coral_reef_boards.each do |board|
        tiles = tile_bag.draw_colors(*PolypTile.available_colors)
        board.add_starting_tiles(tiles)
      end
    end
  end
end

