# To change this template, choose Tools | Templates
# and open the template in the editor.

def Deck *cards
  Deck[*cards]
end

class Deck < Array

  module ArrayExtensions
    def to_deck
      Deck.new self
    end
  end

  def self.standard
    deck = Deck.new
    ['Potato', 'Carrot','Cabbage','Pepper'].each do |suit|
      [6, 7, 8, 9, 10, 11, 12, 13, 14].each do |rank|
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

  def _draw num, operation
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

Array.send :include, Deck::ArrayExtensions