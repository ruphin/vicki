require 'poloniex'
require 'json'
require 'twitter'

POLO_API_SECRET = ENV.fetch 'POLO_API_SECRET'
TWITTER_CONSUMER_SECRET = ENV.fetch 'TWITTER_CONSUMER_SECRET'
TWITTER_ACCESS_TOKEN_SECRET = ENV.fetch 'TWITTER_ACCESS_TOKEN_SECRET'

Poloniex.setup do |config|
  config.key = 'RH0Q9QY3-TSWAUCH5-OO5CL7PB-2MBDT5KA'
  config.secret = POLO_API_SECRET
end

def shortETH
  puts "PLACING SELL ORDER"
  limit = (marketPrice(:short) * 0.95).round(8) # We are prepared to sell down to 95% market price
  volume = holding('ETH')
  puts "PRICE: #{limit} - VOLUME: #{volume}"
  #Poloniex.sell 'BTC_ETH' limit volume
end

def longETH
  puts "PLACING BUY ORDER"
  limit = (marketPrice(:long) * 1.05).round(8) # We are prepared to buy up to 105% market price
  volume = holding('BTC')
  puts "PRICE: #{limit} - VOLUME: #{volume}"
  #Poloniex.buy 'BTC_ETH' limit volume
end

def holding(currency)
  return JSON.parse(Poloniex.balances.body)[currency]
end

def marketPrice(position)
  orderBook = JSON.parse Poloniex.order_book('BTC_ETH').body
  if position == :short
    return orderBook['bids'].first.first.to_f
  elsif position == :long
    return orderBook['asks'].first.first.to_f
  else
    raise 'Invalid position'
  end
end

twitterClient = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = "CKpfdw8uQLwKz03Prveb98dHO"
  config.consumer_secret     = TWITTER_CONSUMER_SECRET
  config.access_token        = "776866644039794688-ZTXReWmOjv3weNI4nH4fULCAN67HNbe"
  config.access_token_secret = TWITTER_ACCESS_TOKEN_SECRET
end

VICKI = "834940874643615744"

begin
  twitterClient.filter(follow: "834940874643615744") do |tweet|
    puts "VICKI POSTED: #{tweet.text}"
     if /short on ETHBTC/ =~ tweet.text
       shortETH
     elsif /long on ETHBTC/ =~ tweet.text
       longETH
     end
  end
rescue Twitter::Error::TooManyRequests => error
  puts "RATE LIMIT REACHED! WAITING 15m"
  # NOTE: Your process could go to sleep for up to 15 minutes but if you
  # retry any sooner, it will almost certainly fail with the same exception.
  sleep 60 * 15
  retry
end
