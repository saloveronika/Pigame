# To change this template, choose Tools | Templates
# and open the template in the editor.

module Pig
  class TurnTracker
    attr_accessor :game, :count

    def initialize game
      @game = game
      @count = 0
    end

    def player
      if @last_player
        index_of_last_player = game.players.index @last_player
        next_player = game.players[index_of_last_player + 1]
        next_player = game.players.first unless next_player
        if $change_priority
          next_player = @last_player
        end
        return next_player
      else
        game.players.first
      end
    end

    def take! player_taking_turn
      if $change_priority
        puts "All good!!!"
      end
      if player_taking_turn != player 
        raise "It's not your turn!"
      else
        
        @last_player = player_taking_turn
        @count += 1
      end
    end
  end
  
  class Player 
    attr_accessor :game, :hand

    def hand= value
      @hand = value.to_deck
      @hand = @hand.sort_by { |card| card.rank  }
    end

    def initialize game
      @game = game
      $used = false
      $change_priority = false
      $cannot_figth = false    
      $cannot_put = false
      $count_steps = 0
    end
   
  
    def step_card trump
      # game.turn.take!(self)
      $change_priority = false
      #select less card not trump or repeat cards
      repeat_card = hand.sort_by { |card| card.rank  }.group_by { |card| card.rank }.values.max_by(&:size)
      less_card = hand.select { |card| card.rank  }.sort_by { |card| card.rank  }.first
      #unless card.suit == trump.suit
      if (less_card and repeat_card)
        if less_card.rank < repeat_card.first.rank 
          @lc = less_card
        else
          @lc = repeat_card
        end
        #remove it from hand
        #Array(@lc).each { |card| hand.delete card }
        del_card = Array(@lc).first 
        hand.delete del_card
      end
    end
       
    
    def fight_card step_cards, trump
      #analyse suit & rank of step
      #if hand has same suit & bigger rank - remove it from hand
      @a = check_for_fight_cards step_cards, trump
      if @a
        #remove cards
        Array(@a).each { |card| hand.delete card }
        $change_priority = false
        puts "Priority #{$change_priority}" 
      end
      @a
    end
    
    def user_step cards
      #game.turn.take!(self)
   
      Array(cards).each { |card| hand.delete card }
    end
    
    def user_fight cards#, trump
      #if cards
      Array(cards).each { |card| hand.delete card }
      # else
      # hand << Array(cards).compact 
      # end
     
    end
    
    def is_there_put_cards table
      @a=[]    
      hand.each do |card|
        table.each do |t| 
          if t.rank == card.rank
            @a+=Array(card)
          end
        end
      end
      if @a.empty?
        return false
      else
        return @a#.first#.length
      end
    end
    
    def check_for_fight_cards step_cards, trump
      @f = Array.new
      @a = Array.new
      @r = Array.new
      #@mark = false
      step_cards.each do |i|
        @f += hand.select { |card| card if ((card.suit == i.suit) and (card.rank > i.rank)) }.sort_by {|card| card.rank}
        
        @r += hand.select {|card| card.rank if ((card.suit == trump.suit) and (i.suit!=trump.suit))}
       # @r.each do |j|
         # if ((i.suit!=trump.suit))
          #  @f += Array(j)
            #@mark = true
        #  end
       # end
      end
      @f.group_by {|card| card.suit}.values.each do |cards|
        @a += Array(cards.min_by {|card| card.rank })
      end
      #puts "In block group_by a=" + @a.to_s + "f=" + @f.to_s
      if (@a.empty? or (@a.length < step_cards.length))
        # add posibility fight with trump cards
        @a += @r.sort_by{|card| card.rank}.first(step_cards.length-@a.length)
      
        #  puts "select trump card"
        # puts "a=" + @a.to_s + "f=" + @f.to_s
        if (@a.empty? or (@a.length < step_cards.length))
          #puts "a is empty"
          return false
        end
      end
      @a
    end
    
    def is_there_fight_cards step_cards, trump
      #check_for_fight_cards step_cards, trump
      @a = Array.new
      step_cards.each do |i|
        @a += hand.select { |card| card if ((card.rank > i.rank) and (card.suit == i.suit))}
        @a += hand.select { |card| card if ((card.suit == trump.suit) and (card.suit != i.suit))}
        @a += hand.select { |card| card if ((card.suit == trump.suit) and (i.suit == card.suit) and (card.rank > i.rank))}
      end
      @a
    end
    
    def loose_step added_cards
      #draw cards of step in hand
      added_cards.uniq!
      hand << added_cards
      hand.flatten!
      hand.uniq!
      puts "You lose step! Add cards to hand"
      #not you turn
      $change_priority =  true
      puts "Priority #{$change_priority}" 
      
    end
    
    def get_card_from_deck trump_card, game
      #number of hand's card
      len = 6 - hand.length
      #draw to 6 from deck
      if len > 0
        d = game.draw_pile.shift(len)
       
        if ((len - d.length)>0 and $used == false)
          d += Array(trump_card)
          $used = true
        end
        
        if (d.compact.empty? and $used == false) 
          d = Array(trump_card)
          $used = true
        end
        hand << Array(d).compact
        hand.flatten!
        puts "d = " + d.to_s
      
        #remove it from deck
      end
      hand.sort_by! { |card| card.rank  }
      
    end
  end
  
  class PigGame
    attr_accessor :players, :draw_pile, :turn
    
    

    def draw_pile= value
      @draw_pile = value.to_deck
    end
    
    def trump_card
      trump = draw_pile.shift(1).first
    end

    def check_suit suit
      a = (suit-['Potato', 'Cabbage'])
      b = (suit-['Carrot', 'Pepper'])
            
      if (a.empty? or b.empty?)
        return false
      end
      
      ['Potato', 'Carrot','Cabbage','Pepper'].each do |standart_suit|
        c = (suit-%w(standart_suit))
        if c.empty?
          return false
        end
      end
      return a
    end
    
    def less_trump_card player, trump
      @trump_suit = trump.suit
      @player_rank = player.hand.map {|card| @player_rank = card.rank if card.suit == @trump_suit }
            
      # sort and get less rank
      less_rank = @player_rank || nil
      return less_rank.compact!.sort.first
    end
    
    def first_player np, players, trump
      np.times do |i|
        ltc = less_trump_card players[i], trump 
        min = i if i==0         
        if ((ltc <=> min) == -1)
          min = i
        end
        if i==(np-1)
          return players[min]
        else 
          return players[0]
        end
      end
    end
    
    def initialize number_of_players
      @turn = TurnTracker.new(self)
      @draw_pile = Deck.standard.shuffle!
     
      @players = []
      number_of_players.times do
        player = Player.new(self)
        player.hand = draw_pile.shift(6)
        #  until check_suit player.hand.map {|card| card.suit} 
        #   player.hand = draw_pile.draw(6)
        #  end
        @players << player
      end
      # @trump = trump_card
      #  @fp = first_player number_of_players, @players, @trump
      #while @fp==nil  
      # @trump = trump_card
      # @fp = first_player number_of_players, @players, @trump
      #end
     
    end

    def winner
      if over?
        players.sort_by {|player| player.hand.length }.first
      end
    end

    def over? 
      return false unless draw_pile.empty?
      puts "#{draw_pile}" + "DDDDDDDD"
      
      a=0
      players.each do |player|
        a+=1 if player.hand.empty?
        puts "#{player.hand}" + "HHHHHHH"
      end
      puts "#{a}" + "AAAAAAA"
      return true if a>0
      
    end
  end

  
end
