class CheckPaymentStatusWorker
  include Sidekiq::Worker
  include UqpayCommon

  def perform(*args)
    orders = Spree::Order.where("payment_state = :payment_state", { payment_state: "balance_due" })

    orders.each do |order|
      payment_source = order.payments.first.source
      
      if payment_source.date.to_i <= (100.minutes.ago.to_i * 1000)
        query_data = {
          merchantid: uqpay_merchant_id,
          transtype: "query",
          uqorderid: payment_source.uqorderid,
          date: payment_source.date
        }

        response = make_request("#{uqpay_host}/query", query_data)
        query = JSON.parse(response)
        
        if payment_source.uqorderid == query.body[uqorderid] 
          order.update(state: "failed", payment_state: "failed")
          order.payments.first.update(state: "failed")
        end
      end
    end    
  end
end