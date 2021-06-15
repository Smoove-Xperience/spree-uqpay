class CreateSpreeUqpayPaymentSources < SpreeExtension::Migration[4.2]
  def change
    create_table :spree_uqpay_payment_sources do |t|
      t.integer :payment_method_id
      t.integer :user_id
      t.string :date
      t.string :methodid
      t.string :message
      t.text :channelinfo
      t.string :acceptcode
      t.string :uqorderid
      t.string :state
    end
  end
end
