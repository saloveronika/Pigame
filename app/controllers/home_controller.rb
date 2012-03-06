class HomeController < ApplicationController
  def index
    #@name = 
  end
  def ajax
    render :text => "Game over!!!"
    #render "index"
  end
end
