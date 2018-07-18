# CoinTracking.info to Bitcoin.tax Converter

## What does it do?

I wrote this script to transfer my trades from CoinTracking.info to Bitcoin.tax in order to file my Canadian taxes. CoinTracking.info does not currently support ACB (Adjusted Cost Base) but thankfully Bitcoin.tax does.

## Requirements

* Ruby 2.5+
* Bundler

## Running

* Copy `config.yml.example` to `config.yml` and change settings as desired
* Run `bundle`
* Then run `./convert`
* Upload all 3 CSV files to Bitcoin.tax manually. They are: `income.csv`, `spending.csv` and `trading.csv`

