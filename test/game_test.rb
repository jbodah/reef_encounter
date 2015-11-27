require 'test_helper'

module ReefEncounter
  class GameTest < Minitest::Spec
    describe 'Game#initialize' do
      it 'accepts a number of players and creates that many players' do
        (1..4).to_a.each do |num_players|
          game = Game.new(num_players)
          assert_equal num_players, game.players.size
        end
      end

      it 'has a number of coral reef boards equal to the number of players' do
        (1..4).to_a.each do |num_players|
          game = Game.new(num_players)
          assert_equal num_players, game.coral_reef_boards.size
        end
      end

      it 'has an open sea board' do
        game = Game.new(2)
        assert !game.open_sea_board.nil?
      end

      describe 'the open sea board' do
        before do
          @game = Game.new(2)
        end

        it 'has 10 coral tiles' do
          assert_equal 10, @game.open_sea_board.coral_tiles.size
        end

        it 'has unique coral tiles' do
          assert_equal 10, @game.open_sea_board.coral_tiles.map(&:corals).map(&:sort).uniq.size
        end
      end

      describe 'the players' do
        it 'gives each a unique color' do
          (1..4).to_a.each do |num_players|
            game = Game.new(num_players)
            assert_equal num_players, game.players.map(&:color).uniq.compact.size
          end
        end

        it 'gives each a player screen does things' do
          (1..4).to_a.each do |num_players|
            game = Game.new(num_players)
            assert game.players.all?(&:player_screen)
          end
        end

        it 'gives each a parrot_fish' do
          (1..4).to_a.each do |num_players|
            game = Game.new(num_players)
            assert game.players.all?(&:parrot_fish)
          end
        end

        it 'gives each player 4 shrimp' do
          (1..4).to_a.each do |num_players|
            game = Game.new(num_players)
            assert game.players.all? { |p| p.shrimp.size == 4 }
          end
        end
      end

      describe 'the tile bag' do
        it 'has 200 polyp tiles, 40 of each color' do
          game = Game.new(2)
          assert_equal 200, game.tile_bag.size

          color_counts = {}
          until game.tile_bag.empty?
            tile = game.tile_bag.draw
            color_counts[tile.color] ||= 0
            color_counts[tile.color] += 1
          end

          assert color_counts.values.all? {|v| v == 40}
        end
      end
    end

    describe 'Game#prepare' do
      it 'draws 5 tiles from the bag and adds them to each coral reef board' do
        (1..4).to_a.each do |num_players|
          game = Game.new(num_players)
          game.prepare
          game.coral_reef_boards.each {|b| assert_equal 5, b.count_tiles}
          assert_equal 200 - (num_players * 5), game.tile_bag.size
        end
      end
    end
  end

  # TODO move to new file
  class CoralTileTest < Minitest::Spec
    describe 'CoralTile#initialize' do
      before do
        @coral_tile = CoralTile.new(:white, :yellow, :green, :blue)
      end

      it 'properly initializes the stronger_coral' do
        assert_equal :white, @coral_tile.stronger_coral
      end

      it 'properly initializes the weaker_coral' do
        assert_equal :yellow, @coral_tile.weaker_coral
      end

      it 'properly initializes the showing_alga' do
        assert_equal :green, @coral_tile.showing_alga
      end

      it 'properly initializes the background_alga' do
        assert_equal :blue, @coral_tile.background_alga
      end
    end

    describe 'CoralTile#flip!' do
      before do
        @coral_tile = CoralTile.new(:white, :yellow, :green, :blue)
      end

      it 'causes the stronger_coral value to switch' do
        assert_equal :white, @coral_tile.stronger_coral
        @coral_tile.flip!
        assert_equal :yellow, @coral_tile.stronger_coral
        @coral_tile.flip!
        assert_equal :white, @coral_tile.stronger_coral
      end

      it 'causes the weaker_coral value to switch' do
        assert_equal :yellow, @coral_tile.weaker_coral
        @coral_tile.flip!
        assert_equal :white, @coral_tile.weaker_coral
        @coral_tile.flip!
        assert_equal :yellow, @coral_tile.weaker_coral
      end

      it 'causes the showing_alga value to switch' do
        assert_equal :green, @coral_tile.showing_alga
        @coral_tile.flip!
        assert_equal :blue, @coral_tile.showing_alga
        @coral_tile.flip!
        assert_equal :green, @coral_tile.showing_alga
      end

      it 'causes the background_alga value to switch' do
        assert_equal :blue, @coral_tile.background_alga
        @coral_tile.flip!
        assert_equal :green, @coral_tile.background_alga
        @coral_tile.flip!
        assert_equal :blue, @coral_tile.background_alga
      end
    end
  end
end
