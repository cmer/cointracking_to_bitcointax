require 'coin_tracking'

require File.join(ROOT_PATH, '/lib/object')
require File.join(ROOT_PATH, '/lib/mapping')
require File.join(ROOT_PATH, '/lib/config')
require File.join(ROOT_PATH, '/lib/utils')
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

def trades_data
  if $config.read_from_cache && File.exists?($config.cache_data_path)
    YAML.load_file($config.cache_data_path)
  else
    api = CoinTracking::Api.new($config.cointracking_api_key, $config.cointracking_secret_key)
    data = api.trades.data
    File.write($config.cache_data_path, data.to_yaml) if $config.cache_data_path
    data
  end
end

def trading_line(id, values)
  txn_type       = convert_type(values['type'])
  buy_coin       = values['buy_currency']
  sell_coin      = values['sell_currency']
  fee_coin       = values['fee_currency']
  buy_coin       = COIN_MAPPING[buy_coin]  || buy_coin
  sell_coin      = COIN_MAPPING[sell_coin] || sell_coin
  fee_coin       = COIN_MAPPING[fee_coin]  || fee_coin
  buy_amount     = values['buy_amount']
  sell_amount    = values['sell_amount']

  line = []
  line << formatted_time(values['time'])
  line << txn_type
  line << ''
  line << buy_coin
  line << eight_decimals(buy_amount)
  line << eight_decimals(sell_amount)
  line << sell_coin
  line << eight_decimals(values['fee_amount'])
  line << fee_coin
  line
end

def spending_line(id, values)
  txn_type    = convert_type(values['type'])
  sell_coin   = values['sell_currency']
  sell_coin   = COIN_MAPPING[sell_coin] || sell_coin
  sell_amount = values['sell_amount']

  line = []
  line << formatted_time(values['time'])
  line << txn_type
  line << ''
  line << sell_coin
  line << eight_decimals(sell_amount)
  line
end

def income_line(id, values)
  txn_type   = convert_type(values['type'])
  buy_coin   = values['buy_currency']
  buy_coin   = COIN_MAPPING[buy_coin] || buy_coin
  buy_amount = values['buy_amount']

  line = []
  line << formatted_time(values['time'])
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

def run
  write_to_output 'TRADING', TRADING_FIELDS.join(',')
  write_to_output 'INCOME', INCOME_FIELDS.join(',')
  write_to_output 'SPENDING', SPENDING_FIELDS.join(',')

  trades_data.each_pair do |id, values|
    next unless id.to_i.to_s == id.to_s
    next unless txn_type = convert_type(values['type'])

    output_type = OUTPUT_TYPE_MAPPING[txn_type]

    line = case output_type
      when 'TRADING';  trading_line(id, values)
      when 'INCOME';   income_line(id, values)
      when 'SPENDING'; spending_line(id, values)
    end

    write_to_output output_type, line.join(',')
  end

  close_outputs
  puts "Done! Files written to #{$config.output_path}."
end

$config = Config.new.load(ARGV[0])
run
