require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

helpers do 
     def calculate_total(cards) # cards is [["H", "3"],... ]
        arr = cards.map{|element| element[1]}
           total = 0
         arr.each do |a|
               if a == "A"
                 total += 11
               else
                   total += a.to_i == 0 ? 10 : a.to_i
               end
           end

           #always correct for aces
           arr.select{|element| element == "A"}.count.times do
               break if total <= 21
             total -= 10
           end

           total
       end

    def card_image(card)

      suit = case card[0]
        when 'H' then 'hearts'
        when 'C' then 'clubs'
        when 'S' then 'spades'
        when 'D' then 'diamonds'
      end

      value = card[1]
      if ['J', 'Q', 'K', 'A'].include?(value)
        value = case card[1]
          when 'J' then 'jack'
          when 'Q' then 'queen'
          when 'K' then 'king'
          when 'A' then 'ace'
        end
      end

      "<img src='/images/cards/#{suit}_#{value}.jpg'class='card_image'>"
    end

    def winner!(msg)
      @play_again = true
      @show_hit_or_stay_button = false
      @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    end

    def loser!(msg)
      @play_again = true
      @show_hit_or_stay_button = false
      @error = "<strong>#{session[:player_name]} loses</strong> #{msg}"
    end

    def tie!(msg)
      @play_again = true
      @show_hit_or_stay_button = false
      @success = "<stong>It's a tie.</strong> #{msg}"
    end
 

  end

before do
  @show_hit_or_stay_button = true
end




get '/'  do
  if session[:player_name]
  redirect '/game'
  else
    redirect '/set_name'
  end
end

get '/set_name' do
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "You must enter a name to play."
    halt erb(:set_name)
  end

  session[:player_name] = params[:player_name]  
  redirect '/game'
end

get '/game' do
  # set up initial game values
  # create a deck and put it in a session
  suits          = ['H','D','C','S']
  card_values    = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(card_values).shuffle!
  #deal the cards
  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  #Player's turn

  erb :game
end

    #hit or stay
post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop

    player_total = calculate_total(session[:player_cards])
    if player_total == 21
      winner!("#{session[:player_name]} hit blackjack.")
    elsif player_total > 21
      loser!("#{session[:player_name]} busted!")
    end  
  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} choose to stay."
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end

 
 get '/game/dealer' do
    @show_hit_or_stay_button = false
    dealer_total = calculate_total(session[:dealer_cards])

    #decision tree
    if dealer_total == 21
      loser!("Sorry, Dealer hit Blackjack. Want to paly again?")
    elsif 
      dealer_total > 21
      winner!("Congrats! The Dealer busted. You win.")
    elsif dealer_total >= 17
      redirect '/game/compare'
    else
      @show_dealer_hit_btn = true
    end


erb :game
 end

    
post '/game/dealer/hit' do

  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'

end

get '/game/compare' do

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])
  @show_hit_or_stay_button = false


  if dealer_total > player_total
    loser!("#{session[:player_name]} stayed at #{player_total}. The house wins with a total of #{dealer_total}")
  elsif dealer_total < player_total
    winner!("Congrats. #{session[:player_name]} wins with a total of #{player_total}! The house stayed at #{dealer_total}")
  else
    tie!("It's a tie with both #{session[:player_name]} and the dealer at #{player_total}.")
  end
      erb :game
end

get '/game/game_over' do
  erb :game_over
  end


