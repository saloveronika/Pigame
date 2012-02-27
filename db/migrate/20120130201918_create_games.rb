class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :username 
      t.text :who_held_step
      t.text :g_id
      t.text :player
      t.text :bot
      t.text :t_card
      t.text :s_cards
      t.text :f_cards
      t.text :d_cards
      t.text :table
     
  
      t.timestamps
    end
  end
end
