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

logger = Logger.new(STDOUT)

def shortETH
  logger.info "PLACING SELL ORDER"
  limit = (marketPrice(:short) * 0.95).round(8) # We are prepared to sell down to 95% market price
  volume = holding('ETH')
  logger.info "PRICE: #{limit} - VOLUME: #{volume}"
  result = Poloniex.sell('BTC_ETH', limit, volume)
  logger.info result
end

def longETH
  logger.info "PLACING BUY ORDER"
  price = marketPrice(:long)
  limit = (price * 1.05).round(8) # We are prepared to buy up to 105% market price
  volume = ((holding('BTC') / price) * 0.95).round(8) # Buy with 95% of our stack to make sure the order doesn't go over budget.
  logger.info "PRICE: #{limit} - VOLUME: #{volume}"
  result = Poloniex.buy('BTC_ETH', limit, volume)
  logger.info result
end

def holding(currency)
  return JSON.parse(Poloniex.balances.body)[currency].to_f
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

 # This is the autorization for @ggvangool - an account that only follows Vicki and never tweets
twitterClient = Twitter::Streaming::Client.new do |config|
  config.consumer_key        = "YdJEqxgvM6KsgfDZSmkn4c93M"
  config.consumer_secret     = TWITTER_CONSUMER_SECRET
  config.access_token        = "196829257-0WqaIpEpfABiaMUQtyfIeWT7ZAFq7Zltn2vx3uQQ"
  config.access_token_secret = TWITTER_ACCESS_TOKEN_SECRET
end

begin
  twitterClient.user() do |tweet|
    if (tweet.class == Twitter::Tweet)
      logger.info "Tweet: #{tweet.text}"
      if /short on ETHBTC/ =~ tweet.text
        shortETH
      elsif /long on ETHBTC/ =~ tweet.text
        longETH
      end
    else
      logger.warn "==================================================="
      logger.warn "#{tweet.class}: #{tweet.inspect}"
      logger.warn "==================================================="
    end
  end
rescue Exception => e
  logger.error "==================================================="
  logger.error "SOMETHING BORKED: #{e.message}"
  logger.error e.backtrace.inspect
  logger.error "==================================================="
  logger.error "WAITING 2m"
  # NOTE: Twitter API resets rate limits every 15 minutes.
  sleep 60 * 2
  retry
end
