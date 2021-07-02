module Spree
  # Gateway for china union payment method
  class Gateway::UqpayAlipay < PaymentMethod
    include UqpayCommon

    def provider_class
      self.class
    end

    def source_required?
      true
    end

    def auto_capture?
      false
    end

    # Spree usually grabs these from a Credit Card object but when using
    # Adyen Hosted Payment Pages where we wouldn't keep # the credit card object
    # as that entered outside of the store forms
    def actions
      %w{void}
    end

    # Indicates whether its possible to void the payment.
    def can_void?(payment)
      !payment.void?
    end

    # Indicates whether its possible to capture the payment
    def can_capture?(payment)
      payment.pending? || payment.checkout?
    end

    def method_type
      "uqpay_alipay"
    end

    def cancel(payment_source)
      response = self.cancel({
        'orderid': options[:order_id],
        'uqorderid': payment_source.uqorderid,
        'amount': (amount.to_f / 100).round(2),
      })
      
      if (response.status == 200)
        
      end
    end

    def authorize(amount, source, options = {})
      response = self.pay({
        'orderid': options[:order_id],
        'methodid': 2002,
        'amount': (amount.to_f / 100).round(2),
        'currency': options[:currency],
      })

      if (response.status == 200)
        response_body = JSON.parse(response.body)
        source.date = response_body["date"]
        source.methodid = response_body["methodid"]
        source.message = response_body["message"]
        source.channelinfo = response_body["channelinfo"]
        source.acceptcode = response_body["acceptcode"]
        source.uqorderid = response_body["uqorderid"]
        source.state = response_body["state"]
        source.save!
        ActiveMerchant::Billing::Response.new(true, 'Uqpay payment created.')
      else
        ActiveMerchant::Billing::Response.new(false, 'Failed to create uqpay payment.')
      end
    end

    def capture(*_args)
      ActiveMerchant::Billing::Response.new(true, 'Uqpay will automatically capture the amount after creating a shipment.')
    end
  end
end
