require 'active_record'
require 'attribute_normalizer'
require 'rounding'
require 'byebug'

ActiveRecord::Schema.verbose = false
ActiveRecord::Base.establish_connection(adapter: 'sqlite3', database: ':memory:')

ActiveRecord::Base.send :include, AttributeNormalizer

ActiveRecord::Schema.define(version: 1) do
  create_table "trades" do |t|
    t.decimal  "buy_amount"
    t.string   "buy_currency"
    t.decimal  "sell_amount"
    t.string   "sell_currency"
    t.decimal  "fee_amount"
    t.string   "fee_currency"
    t.string   "txn_type"
    t.string   "exchange"
    t.string   "group"
    t.string   "comment"
    t.string   "imported_from"
    t.datetime "time"
    t.datetime "imported_time"
    t.string   "trade_id"
    t.string   "order_hash"
  end
end

class Trade < ActiveRecord::Base
  before_save :set_order_hash

  normalize_attribute :txn_type do |v|
    v.strip.downcase
  end

  normalize_attribute :buy_currency, :sell_currency, :fee_currency do |v|
    v.strip.upcase
  end

  def self.from_cointracking(id, values)
    t = Trade.new
    t.trade_id = id
    t.txn_type = values.delete('type')

    values.each_pair do |k, v|
      next unless t.respond_to?("#{k}=")
      t[k] = if k =~ /time/
        DateTime.strptime(v, '%s')
      else
        v
      end
    end
    t
  end

  private

  def set_order_hash
    t = self.time.floor_to(1.minute)
    self.order_hash = Digest::SHA256.hexdigest("#{t}-#{self['buy_currency']}-#{self['sell_currency']}-#{self['fee_currency']}")
  end
end

