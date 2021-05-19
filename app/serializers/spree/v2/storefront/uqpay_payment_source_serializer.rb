module Spree
  module V2
    module Storefront
      class UqpayPaymentSourceSerializer < BaseSerializer
        attributes :payment_method_id, :user_id, :date, :methodid, 
                   :message, :channelinfo, :acceptcode, :uqorderid, :state
      end
    end
  end
end
