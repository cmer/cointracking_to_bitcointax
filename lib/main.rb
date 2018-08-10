require 'bundler/setup'
require 'digest'

require File.join(ROOT_PATH, '/lib/object')
require File.join(ROOT_PATH, '/lib/mapping')
require File.join(ROOT_PATH, '/lib/config')
require File.join(ROOT_PATH, '/lib/utils')
require File.join(ROOT_PATH, '/lib/database')

include Utils

TRADING_FIELDS  = %w(DATE ACTION SOURCE SYMBOL VOLUME TOTAL CURRENCY FEE FEECURRENCY)
INCOME_FIELDS   = %w(DATE ACTION SOURCE SYMBOL VOLUME TOTAL CURRENCY)
SPENDING_FIELDS = %w(DATE ACTION SOURCE SYMBOL VOLUME)

def convert_type(ct_type)
  TYPE_MAPPING.each_key do |regexp|
    return TYPE_MAPPING[regexp] if ct_type =~ regexp
  end

  nil
end

def retrieve_trades_data
  puts "Retrieving trades from CoinTracking..."
  if $config.read_from_cache && File.exists?($config.cache_data_path)
    data = YAML.load_file($config.cache_data_path)
  else
    api = CoinTracking::Api.new($config.cointracking_api_key, $config.cointracking_secret_key)
    data = api.trades.data
    File.write($config.cache_data_path, data.to_yaml) if $config.cache_data_path
  end

  puts "Saving trades to memory..."
  data.each_pair do |id, values|
    next unless id.to_i.to_s == id.to_s
    t = Trade.from_cointracking(id, values)
    t.save!
    print '.'
  end

  print "\n"
end


def order_fingerprint(ct_trade)
  Digest::SHA256.hexdigest "#{values['time']}-#{values['buy_currency']}-#{values['sell_currency']}-#{values['fee_currency']}"
end

def trading_line(trade)
  txn_type    = convert_type(trade.txn_type)
  buy_coin    = trade.buy_currency
  sell_coin   = trade.sell_currency
  fee_coin    = trade.fee_currency
  buy_coin    = COIN_MAPPING[buy_coin]  || buy_coin
  sell_coin   = COIN_MAPPING[sell_coin] || sell_coin
  fee_coin    = COIN_MAPPING[fee_coin]  || fee_coin
  buy_amount  = trade.buy_amount
  sell_amount = trade.sell_amount

  line = []
  line << formatted_time(trade.time)
  line << txn_type
  line << ''
  line << buy_coin
  line << eight_decimals(buy_amount)
  line << eight_decimals(sell_amount)
  line << sell_coin
  line << eight_decimals(trade.fee_amount)
  line << fee_coin
  line
end

def spending_line(trade)
  txn_type    = convert_type(trade.txn_type)
  sell_coin   = trade.sell_currency
  sell_coin   = COIN_MAPPING[sell_coin] || sell_coin
  sell_amount = trade.sell_amount

  line = []
  line << formatted_time(trade.time)
  line << txn_type
  line << ''
  line << sell_coin
  line << eight_decimals(sell_amount)
  line
end

def income_line(trade)
  txn_type   = convert_type(trade.txn_type)
  buy_coin   = trade.buy_currency
  buy_coin   = COIN_MAPPING[buy_coin] || buy_coin
  buy_amount = trade.buy_amount

  line = []
  line << formatted_time(trade.time)
  line << txn_type
  line << ''
  line << buy_coin
  line << eight_decimals(buy_amount)

  if txn_type == 'GIFTIN'
    line << '0.01'
    line << 'USD'
  else
    2.times { line << '' }
  end

  line
end


def write_trade_lines_for_order_hash(order_hash)
  rel = Trade.where(order_hash: order_hash)

  if $config.combine_trades?
    grouped_rel = rel.group(:order_hash)
    template_row = rel.first.dup

    %i(buy_amount sell_amount fee_amount).each do |col|
      template_row[col.to_s] = grouped_rel.sum(col)[order_hash]
    end
    @combined_lines_saved += rel.count - 1
    rows = [template_row]
  else
    rows = rel
  end

  rows.each do |r|
    puts trading_line(r).join(",")
    write_to_output 'TRADING', trading_line(r).join(",")
  end
end

def run
  @combined_lines_saved = 0
  @current_order_trades = []

  retrieve_trades_data

  # Process trades
  order_hashes = Trade.where(txn_type: 'trade').pluck(:order_hash).uniq
  write_to_output 'TRADING', TRADING_FIELDS.join(',')

  order_hashes.each do |oh|
    write_trade_lines_for_order_hash(oh)
  end

  # Process Income & Spending
  write_to_output 'INCOME', INCOME_FIELDS.join(',')
  write_to_output 'SPENDING', SPENDING_FIELDS.join(',')

  Trade.where.not(txn_type: 'Trade').each do |t|
    next unless txn_type = convert_type(t.txn_type)
    output_type = OUTPUT_TYPE_MAPPING[txn_type]

    case output_type
    when 'INCOME'
      line = income_line(t)
    when 'SPENDING'
      line = spending_line(t)
    end

    write_to_output(output_type, line.join(',')) if line.is_a?(Array)
  end

  close_outputs
  puts "Done! Files written to #{$config.output_path}."
  puts "Reduced output by #{@combined_lines_saved} lines by combining trades." if $config.combine_trades?
end

$config = Config.new.load(ARGV[0])
run
