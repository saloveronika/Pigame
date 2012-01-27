# To change this template, choose Tools | Templates
# and open the template in the editor.
class Deck < Array
  
  def self.standard
    deck = Deck.new
    ['Potato', 'Carrot','Cabbage','Pepper'].each do |suit|
      [6, 7, 8, 9, 10, 'Jack', 'Queen', 'King', 'Ace'].each do |rank|
        deck << Card.new(rank, suit)
      end
    end
    deck
  end
  
  def draw_from_top num = 1
    _draw num, :shift
  end

  alias draw draw_from_top

  def draw_from_bottom num = 1
    _draw num, :pop
  end
  
  private

  def _draw (num, operation)
    if num.is_a?(Card)
      delete num
    else
      if num == 1
        send(operation)
      else
        cards = []
        num.times { cards << send(operation) }
        cards
      end
    end
  end
  
end


class Card
  attr_accessor :rank, :suit
  
  def initializer(rank,suit)
    @rank = rank.to_s
    @suit = suit.sub(/s$/, '')
  end
  
   def == another_card
    rank == another_card.rank and suit == another_card.suit
  end

  def name
    "#{ rank } of #{ suit }s"
  end

  alias to_s name
  
  def inspect
    "<Card: \"#{ name }\">"
  end
  
  def self.parse name
    name = name.to_s.sub(/^the( )?/i, '')

    if name =~ /^(\w+) of (\w+)$/i
      Card.new $1, $2
    elsif name =~ /^(\w+)of(\w+)$/i
      Card.new $1, $2
    end
  end

  class << self
    alias [] parse
  end
  
end

module CardConstant
  def const_missing name
    if card = Card.parse(name)
      return card
    else
      super
    end
  end
end

Object.send :extend, CardConstant