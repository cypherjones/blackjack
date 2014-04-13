require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 500

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
               break if total <= BLACKJACK_AMOUNT
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
      session[:player_pot] = session[:player_pot] + session[:player_bet]
      @winner = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
    end

    def loser!(msg)
      @play_again = true
      @show_hit_or_stay_button = false
      session[:player_pot] = session[:player_pot] - session[:player_bet]
      @loser = "<strong>#{session[:player_name]} loses</strong> #{msg}"
    end

    def tie!(msg)
      @play_again = true
      @show_hit_or_stay_button = false
      @winner = "<stong>It's a tie.</strong> #{msg}"
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
  session[:player_pot] = INITIAL_POT_AMOUNT
  erb :set_name
end

post '/set_name' do
  if params[:player_name].empty?
    @error = "You must enter a name to play."
    halt erb(:set_name)
  end

  session[:player_name] = params[:player_name]  
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i == 0
    @error = "You have to make a bet."
    halt erb(:bet)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "You can't bet more than you have, which is $#{session[:player_pot]}"
    halt erb(:bet)
  else
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end


get '/game' do
  session[:turn] = session[:player_name]

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
    if player_total == BLACKJACK_AMOUNT
      winner!("#{session[:player_name]} hit blackjack.")
    elsif player_total > BLACKJACK_AMOUNT
      loser!("#{session[:player_name]} busted!")
    end  

  erb :game, layout: false
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} choose to stay."
  @show_hit_or_stay_button = false
  redirect '/game/dealer'
end


 get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_button = false
  
  dealer_total = calculate_total(session[:dealer_cards])

    #decision tree
    if dealer_total == BLACKJACK_AMOUNT
      loser!("Sorry, Dealer hit Blackjack. Want to paly again?")
    elsif 
      dealer_total > BLACKJACK_AMOUNT
      winner!("Congrats! The Dealer busted. You win.")
    elsif dealer_total >= DEALER_MIN_HIT
      redirect '/game/compare'
    else
      @show_dealer_hit_btn = true
    end


erb :game, layout: false
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
    erb :game, layout: false
end

get '/game/game_over' do
  erb :game_over
  end


