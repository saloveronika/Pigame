# To change this template, choose Tools | Templates
# and open the template in the editor.

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