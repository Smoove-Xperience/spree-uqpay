module Spree
    module UqpayCommon
      extend ActiveSupport::Concern
  
      class RecurringDetailsNotFoundError < StandardError; end
      class MissingCardSummaryError < StandardError; end
  
      included do
        preference :uqpay_host, :string
        preference :uqpay_public_key, :string
        preference :uqpay_private_key, :string
    
        def pay
          Faraday.post(uqpay_host) do |req|
            req.merchant_id= ENV["UQ_PAYMENT_MERCHANT_ID"]
            req.tranver_type= "pay"
            req.orderid= ""
            req.methodid= 2002
            req.amount="0.01"
            req.currency= "SGD"
            req.transname= "TopUp"
            req.quantity="1"
            req.returnurl=ENV["UQ_PAYMENT_CALLBACK_URL"]
            req.callbackurl=ENV["UQ_PAYMENT_CALLBACK_URL"]
            req.date=1611741568985
            req.clienttype="1"
            req.clientip="22"
            req.signtype="RSA"
            req.sign=""
          end
        end

        def cancel
        end
      end
    end
  end
end
  