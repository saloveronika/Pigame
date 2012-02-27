class GamesController < ApplicationController
  include Pig
  require 'card'
  require 'yaml'
  
  before_filter :get_game_from_db, :except => :index
  after_filter :put_game_to_db, :except => :index
  
  
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
   
    if @game.save
      session[:id] = @game.id
    else
      render :text => "Error!"
    end
  end
  
  def step 
    @held_step = "player"
    if @player.hand.length > 0
    @step = @player.user_step YAML.load(params[:cards]) unless $cannot_put
    @fight = @bot.fight_card @step, @trump  unless $cannot_figth
    
    @table += @step
    end
    @put_card = @player.is_there_put_cards(@table)
    if @fight
      @table += @fight
    else
      $cannot_figth = true
      #flash[:notice] = "Computer loose step! Do you wanna add card?"
      #@put_card = @player.is_there_put_cards(@table)
      
      if @put_card 
        $cannot_put = true unless @bot.hand.length >= @put_card.length 

      end
      
      @bot.loose_step @table unless (@put_card and (not $cannot_put)     )
      
    end
    
  end
  
  def end_step
    if @g.over?
      render :text => "Game over!!!"
    end
    
    #clear table, step, fight
    @table.clear if @table
    @step.clear if @step
    @fight.clear if @fight
    $cannot_figth = false
    $cannot_put = false
    get_card_from_deck
    
    if @held_step == "player"
      if $change_priority
        render "index"
      else
        redirect_to games_bot_step_path
      end
    elsif @held_step == "bot"
      if $change_priority
        redirect_to games_bot_step_path
      else
        render "index"
      end
    end
        
  end
  
  def bot_step
    @held_step = "bot"
    if @bot.hand.length > 0
      @step = Array(@bot.step_card @trump )
      @table += @step
    end
    render games_fight_path
  end

  def fight
    @fight = @player.user_fight Array(YAML.load(params[:cards])) 
    @table += @fight
    if @fight
      @step = @bot.is_there_put_cards @table
      if @step
        @step = @step.first
        @step = Array(@step)
        @table += @step
        @bot.hand.delete @step.first
      end     
    end
  end
  
  def loose_fight
    if @step
      $cannot_fight = true
      @put_card = @bot.is_there_put_cards @table
      if @put_card 
        $cannot_put = true unless @player.hand.length >= @put_card.length        
      end
      @player.loose_step @table# unless (@put_card and (not $cannot_put)     )
    end
    redirect_to games_end_step_path
  end

  private
  
  def get_game_from_db
    @game = Game.where(:id => session[:id]).first
   
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
    
    #@game = Game.where(:id => session[:id]).first
    @game.attributes = {:g_id => ser_obj_g, :who_held_step => ser_obj_held_step, :player => ser_obj_player, :bot => ser_obj_bot, :s_cards => ser_obj_step, :f_cards => ser_obj_fight, :table => ser_obj_table}
    
    render :text => "error" unless @game.save
    @table.each do |t|
      puts "put game to db"
      puts t
    end
  end
  
  def get_card_from_deck
    @player.get_card_from_deck @trump
    @bot.get_card_from_deck @trump
  end
 
end
