class CheckPaymentStatusWorker
  include Sidekiq::Worker

  def perform(*args)
    orders = Spree::Order.where("payment_state = :payment_state", { payment_state: "balance_due" })
    
    orders.each { |order| order.payments.first.payment_method.check_payment_status(order) }    
  end
end