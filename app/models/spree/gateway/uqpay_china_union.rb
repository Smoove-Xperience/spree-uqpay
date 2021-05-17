module Spree
  # Gateway for china union payment method
  class Gateway::UqpayChinaUnion < Gateway
    include UqpayCommon

    def provider_class
      self.class
    end

    def source_required?
      true
    end

    def auto_capture?
      true
    end

    # Spree usually grabs these from a Credit Card object but when using
    # Adyen Hosted Payment Pages where we wouldn't keep # the credit card object
    # as that entered outside of the store forms
    def actions
      %w{capture void}
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
      "uqpay_china_union"
    end

    # def process(*args)
    #  @args = args
    #  binding.pry
    # end

    def purchase(amount, source, options = {})
      response = self.pay({
        'orderid': options[:order_id],
        'methodid': 2001,
        'amount': amount / 100,
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
        ActiveMerchant::Billing::Response.new(true, 'Order created')
      else
        ActiveMerchant::Billing::Response.new(false, "Order could not be created")
      end
      
    end

    def authorize(*_args)
      ActiveMerchant::Billing::Response.new(true, 'Mollie will automatically capture the amount after creating a shipment.')
    end

    def capture(amount, transaction_details, options = {})
      ActiveMerchant::Billing::Response.new(true, 'Mollie will automatically capture the amount after creating a shipment.')
    end

    def void(amount, transaction_details, options = {})
      @amount = amount
      @transaction_details = transaction_details
      @options = options
      binding.pry
    end
  end
end
