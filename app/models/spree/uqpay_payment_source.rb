module Spree
  class UqpayPaymentSource < Spree::Base
    belongs_to :payment_method
    has_many :payments, as: :source

    def actions
      []
    end

    def transaction_id
      payment_id
    end

    def method_type
      'uqpay_payment_source'
    end
  end
end
