class CreateUqpayTransactionHistory < ActiveRecord::Migration[6.0]
  def change
    create_table :uqpay_transaction_histories do |t|
      t.string :orderid
      t.string :methodid
      t.float :amount
      t.string :currency
      t.string :transname
      t.string :quantity
      t.string :callbackurl
      t.string :date
      t.string :clienttype
      t.string :signtype
      t.string :sign    
    end
  end
end
