class GamesController < ApplicationController
  include Pig
  require 'card'
  require 'yaml'
  
  before_filter :get_game_from_db, :except => :index
  after_filter :put_game_to_db, :except => [:index, :end_step]
  
  def index
    @g = Pig::PigGame.new(2)
    @player, @bot = @g.players
    @trump = @g.trump_card
    @held_step = "player"
    #@fp = @g.first_player 2, @ph, @trump
        
    ser_obj_g = YAML.dump(@g)
    ser_obj_player = YAML.dump(@player)
    ser_obj_bot = YAML.dump(@bot)
    ser_obj_trump = YAML.dump(@trump)   
    ser_obj_held_step = YAML.dump(@held_step)
    
    @game = Game.new(:username => "user", :who_held_step => ser_obj_held_step, :g_id => ser_obj_g, :player => ser_obj_player, :bot => ser_obj_bot, :t_card => ser_obj_trump)
   
    render :text => "Error!" unless @game.save
   
  end
  
  def step
    l = YAML.load(params[:cards])
    if add_cards_to_table l
      $count_steps += 1
      @held_step = "player"
      if @player.hand.length > 0
        @step = @player.user_step l unless $cannot_put
        @fight = @bot.fight_card @step, @trump  unless $cannot_figth
        @table += @step 
      end
      @put_card = @player.is_there_put_cards(@table)
      if @fight
        puts "#{@fight}" + "fight"
        @table += @fight unless $cannot_figth
      else
        $cannot_figth = true
        if $change_priority
          handlen = @bot.hand.length-$count_steps-1
        else
          handlen = @bot.hand.length-1
        end
        if (@put_card and handlen)
          $cannot_put = true unless (($count_steps < 6) and (handlen >= @put_card.length-$count_steps) ) #-$count_steps
          puts "bot hand length " + "#{@bot.hand.length}"
          puts "put card length " + "#{@put_card.length}"
          puts "table length" + "#{@table.length}"
          puts "count steps " + "#{$count_steps}"
          puts "cannot put " + "#{$cannot_put}"
           puts "handlen " + "#{handlen}"
        end
        if $change_priority 
          @bot.loose_step @step
        else
          @bot.loose_step @table 
        end
      end
    else
      render "step"
    end
  end
  
  def end_step
    $count_steps = 0
    @g.players.clear
    @g.players << @player
    @g.players << @bot
    if @g.over?
      render "game_over"
      @game.destroy
    else
      #clear table, step, fight
      @table.clear if @table
      @step.clear if @step
      @fight.clear if @fight
      $cannot_figth = false
      $cannot_put = false
      get_card_from_deck
      put_game_to_db
      
      if @held_step == "player"
        if $change_priority
          render "index"
        else
          redirect_to games_bot_step_path(:id => @game.id)
        end
      elsif @held_step == "bot"
        if $change_priority
          redirect_to games_bot_step_path(:id => @game.id)
        else
          render "index"
        end
      end
      
    end   
    
  end
  
  def bot_step
    unless (@held_step == "bot" and not($change_priority))
      @held_step = "bot"
      if @player.hand.length > 0
        @step = Array(@bot.step_card @trump )
        @table += @step
      end
    end
    render games_fight_path
  end

  def fight
    l = YAML.load(params[:cards])
    if add_cards_to_table l
      $count_steps += 1
      @fight = @player.user_fight Array(l) 
      if @fight
        @table += @fight
        @step = @bot.is_there_put_cards @table
        if @player.hand.length > 0
          if @step
            @step = @step.first
            @step = Array(@step)
            @table += @step
            @bot.hand.delete @step.first
          end   
        end
      end
    else
      render "fight"
    end
  end
  
  def loose_fight
    if @step
      $cannot_fight = true
      @put_card = @bot.is_there_put_cards @table
      
      if $change_priority
        handlen = @player.hand.length-@table.length-1
      else
        handlen = @player.hand.length
      end
      
      if @put_card 
        unless (($count_steps < 6) and (handlen >= @put_card.length) )
          $cannot_put = true
          
        end       
      end
      @player.loose_step @table if handlen>0
      
      if (@put_card and handlen)
        @put_card = @put_card.first(handlen) if handlen > 0
        
        @table += @put_card
        puts "player hand length " + "#{@player.hand.length}"
        @player.loose_step @put_card if handlen > 0
        puts "bot hand length " + "#{@player.hand.length}"
        puts "put card length " + "#{@put_card.length}"
        puts "table length" + "#{@table.length}"
        puts "count steps" + "#{$count_steps}"
        puts "cannot put" + "#{$cannot_put}"
        puts "handlen " + "#{handlen}"
        Array(@put_card).each { |c| @bot.hand.delete c }
      end
    end 
    redirect_to games_end_step_path(:id => @game.id)
  end

  def ajax
    render :text => "Game over!!!"
    #render "index"
  end
  
  private
  
  def get_game_from_db
    @game = Game.find(params[:id])
   
    @g = YAML.load(@game.g_id)
    @player = YAML.load(@game.player)
    @bot = YAML.load(@game.bot)
    @trump = YAML.load(@game.t_card)
    @held_step = YAML.load(@game.who_held_step)
   
    step = @game.s_cards
    @step = YAML.load(step) if step 
    
    fight = @game.f_cards
    @fight = YAML.load(fight) if fight
    
    table = @game.table
    if table
      @table = YAML.load(table) 
    else
      @table = []
    end
    if @table
      @table.each do |t|
        puts "get game from db"
        puts t
      end
    end
  end
  
  def put_game_to_db
    ser_obj_g = YAML.dump(@g)
    ser_obj_player = YAML.dump(@player)
    ser_obj_bot = YAML.dump(@bot)
    ser_obj_step = YAML.dump(@step)
    ser_obj_fight = YAML.dump(@fight)
    ser_obj_table = YAML.dump(@table)
    ser_obj_held_step = YAML.dump(@held_step)
    
    @game.attributes = {:g_id => ser_obj_g, :who_held_step => ser_obj_held_step, :player => ser_obj_player, :bot => ser_obj_bot, :s_cards => ser_obj_step, :f_cards => ser_obj_fight, :table => ser_obj_table}
    
    render :text => "error" unless @game.save
    @table.each do |t|
      puts "put game to db"
      puts t
    end
  end
  
  def get_card_from_deck
    if @game.who_held_step == "player"
      @player.get_card_from_deck @trump, @g
      @bot.get_card_from_deck @trump, @g
    else
      @bot.get_card_from_deck @trump, @g
      @player.get_card_from_deck @trump, @g
    end
    
  end
  
  def over
    @g.players.clear
    @g.players << @player
    @g.players << @bot
    if @g.over?
      render :text => "Game over!!!"
    end 
  end
  
  def add_cards_to_table add_card
    unless @table.include?(add_card)
      true
    else
      false
    end
  end
  
end
