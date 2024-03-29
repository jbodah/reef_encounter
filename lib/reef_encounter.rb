require 'reef_encounter/version'

class String
  def pluralize(val)
    val == 1 ? self : self + 's'
  end
end

module ReefEncounter
  class OpenSeaBoard
    attr_reader :coral_tiles

    class Space
      attr_accessor :larva_cube
      attr_reader :larva_cube_color, :tiles

      def initialize(larva_cube_color)
        @larva_cube_color = larva_cube_color
        @tiles = []
      end

      def add_tiles(*tiles)
        tiles.each { |t| add_tile(t) }
      end

      def add_tile(tile)
        @tiles << tile
      end
    end

    def initialize
      @coral_tiles = CoralTile.initial_distribution
      @spaces = LarvaCube.available_colors.map do |c|
        Space.new(c)
      end
    end

    def each_space
      enum = Enumerator.new do |yielder|
        @spaces.each do |space|
          yielder.yield space
        end
      end

      block_given? ? enum.each(&Proc.new) : enum
    end
  end

  class Player
    def self.available_colors
      %i{green purple red yellow}
    end

    attr_reader :color, :shrimp, :parrot_fish, :player_screen

    def initialize(color)
      @color = color
      @parrot_fish = ParrotFish.new(color)
      @player_screen = PlayerScreen.new(color)
      @player_screen.behind.shrimp = 4.times.map { Shrimp.new(color) }
    end

    def to_s
      "#{@color} player".capitalize
    end

    def supply_report
      "In Front of Screen: #{@player_screen.in_front_of}\nBehind Screen: #{@player_screen.behind}"
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
    # Helper class
    class Supply
      def initialize(cubes)
        @cubes_by_color = cubes.reduce({}) do |hsh, cube|
          hsh[cube.color] ||= []
          hsh[cube.color] << cube
          hsh
        end
      end

      # TODO optimize
      def draw_colors(*colors)
        colors.map { |c| draw_color(c) }
      end

      def draw_color(color)
        raise if @cubes_by_color[color].empty?
        @cubes_by_color[color].pop
      end

      def replace(*cubes)
        cubes.each { |c| @cubes_by_color[c.color] << c }
      end
    end

    def self.available_colors
      %i{grey orange pink white yellow}
    end

    def self.initial_distribution
      10.times.flat_map { available_colors.map { |c| new(c) } }
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

    def to_s
      @color
    end

    def <=>(o)
      @color <=> o.color
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
      @eatten = []
    end

    def eat(thing)
      @eatten << thing
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
    class Position
      attr_accessor :shrimp, :tiles, :cubes

      def initialize
        @shrimp = []
        @tiles = []
        @cubes = []
      end

      def to_s
        (["#{@shrimp.size} shrimp"] +
          @tiles.group_by(&:color).map {|color, set| "#{set.size} #{color} #{'tile'.pluralize(set.size)}"} +
          @cubes.group_by(&:color).map {|color, set| "#{set.size} #{color} #{'cube'.pluralize(set.size)}"}).join(', ')
      end
    end

    attr_reader :behind, :in_front_of

    def initialize(color)
      @color = color
      @behind = PlayerScreen::Position.new
      @in_front_of = PlayerScreen::Position.new
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

    def draw(n = 1)
      raise "Can't draw! Tile Bag is empty!" if empty?
      (n > 1) ? @tiles.pop(n) : @tiles.pop
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
    class IO
      def puts(s)
        $stdout.puts(s)
      end

      def gets
        $stdin.gets
      end

      def prompt_player(player, msg, choices)
        puts "\n#{player}, #{msg}"
        choices.sort!
        choices.each_with_index do |c, idx|
          puts "\t#{idx}. #{c.to_s}"
        end
        # Todo find something better
        puts "\n#{player.supply_report}"
        choice_idx = gets.strip
        # todo validate
        choices[choice_idx.to_i]
      end
    end

    attr_reader :players, :coral_reef_boards, :open_sea_board, :tile_bag

    alias_method :player_order, :players

    def initialize(num_players, io = Game::IO.new)
      raise 'Invalid number of players' unless [2, 3, 4].include?(num_players)

      @players = Player.available_colors.first(num_players).map do |c|
        Player.new(c)
      end.shuffle
      @tile_bag = TileBag.new(PolypTile.initial_distribution)
      @coral_reef_boards = CoralReefBoard.starting_boards.shuffle.first(num_players)
      @open_sea_board = OpenSeaBoard.new
      larva_cubes = LarvaCube.initial_distribution
      @larva_cube_supply = LarvaCube::Supply.new(larva_cubes)
      @io = io
    end

    def prepare
      prepare_coral_reef_boards
      prepare_open_sea_board
      prepare_player_resources
    end

    def start
      @io.puts 'Starting game...'
      prompt_each_player_to_select_tile_for_parrot_fish
      prompt_each_player_to_choose_two_cubes
    end

    private

    def prompt_each_player_to_choose_two_cubes
      @players.each do |p|
        2.times do
          color = @io.prompt_player(p, "please select a larva cube to put beind your player screen",
                                    LarvaCube.available_colors)
          cube = @larva_cube_supply.draw_color(color)
          p.player_screen.behind.cubes << cube
        end
      end
    end

    def prompt_each_player_to_select_tile_for_parrot_fish
      @players.each do |p|
        tile = @io.prompt_player(p, "please select a polyp tile to put in your parrot fish",
                                 p.player_screen.behind.tiles)
        p.player_screen.behind.tiles.delete(tile)
        p.parrot_fish.eat(tile)
      end
    end

    def prepare_player_resources
      @io.puts 'Preparing the player resources...'
      queue = case @players.size
              when 2 then [6, 9]
              when 3 then [6, 7, 9]
              when 4 then [6, 7, 8, 9]
              else
                raise
              end
      player_order.each do |p|
        p.player_screen.behind.tiles += @tile_bag.draw(queue.shift)
      end
    end

    def prepare_coral_reef_boards
      @io.puts 'Preparing the coral reef boards...'
      tile_colors = PolypTile.available_colors
      @coral_reef_boards.each do |board|
        tiles = tile_bag.draw_colors(*tile_colors)
        board.add_starting_tiles(tiles)
      end
    end

    def prepare_open_sea_board
      # TODO optimize
      @io.puts 'Preparing the open sea board...'
      cube_colors = LarvaCube.available_colors 
      @open_sea_board.each_space do |space|
        space.larva_cube = @larva_cube_supply.draw_color(space.larva_cube_color)
      end

      # todo randomly select color and add 3, 3, 3, 2, 1
      tile_sets = [3, 3, 3, 2, 1].map { |num_tiles| @tile_bag.draw(num_tiles) }
      @open_sea_board.each_space do |space|
        space.add_tiles(*tile_sets.pop)
      end
    end
  end
end

