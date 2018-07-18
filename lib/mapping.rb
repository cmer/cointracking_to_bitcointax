COIN_MAPPING = {
  "IOT" => "MIOTA",
  "AIO" => "AION"
}

TYPE_MAPPING = {
  /trade/i           => 'BUY',
  /income/i          => 'INCOME',
  /mining/i          => 'MINING',
  /gift\/tip\(in\)/i => 'GIFTIN',
  /gift/i            => 'GIFT',
  /spend/i           => 'SPEND',
  /donation/i        => 'DONATION',
  /stolen/i          => 'STOLEN',
  /lost/i            => 'LOST'
}

OUTPUT_TYPE_MAPPING = {
  'BUY'         => 'TRADING',
  'INCOME'      => 'INCOME',
  'MINING'      => 'INCOME',
  'GIFTIN'      => 'INCOME',
  'SPEND'       => 'SPENDING',
  'DONATION'    => 'SPENDING',
  'GIFT'        => 'SPENDING',
  'STOLEN'      => 'SPENDING',
  'LOST'        => 'SPENDING'
}

OUTPUT_FILES_MAPPING = {
  'TRADING'  => 'trading.csv',
  'SPENDING' => 'spending.csv',
  'INCOME'   => 'income.csv'
}
