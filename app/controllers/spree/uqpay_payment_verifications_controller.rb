module Spree
  class UqpayPaymentVerificationsController < BaseController    
    skip_before_action :verify_authenticity_token, only: [:create]

    PAYMENT_METHODS = { 
      "2000": "Spree::Gateway::UqpayWechat", 
      "2001":  "Spree::Gateway::UqpayChinaUnion", 
      "2002": "Spree::Gateway::UqpayAlipay" 
    }

    def create            
      return head(:bad_request) unless payment_method.verify_signature(permitted_params.to_h)

      source = UqpayPaymentSource.find_by(uqorderid: permitted_params["uqorderid"])

      return head(:not_found) unless source.present?

      @payment = source.payment

      case permitted_params["state"]
        when "Ready"
          transition_to_pending!
        when "Paying"  
          transition_to_pending!
        when "Success"
          transition_to_paid!      
        when "Closed"          
          transition_to_failed!
        when "Failed"          
          transition_to_failed!          
      end 
    
      source.update(state: permitted_params["state"])
      head :ok
    end

    private

    def payment_method
      Spree::PaymentMethod.find_by_type PAYMENT_METHODS[permitted_params["methodid"].to_sym]
    end

    def transition_to_pending!
      @payment.pend! unless @payment.pending?
    end

    def transition_to_paid!
      return if @payment.completed?

      @payment.complete!
    end

    def transition_to_failed!
      return if @payment.failed?

      @payment.failure!
      @payment.order.update(shipment_state: "canceled")
    end  

    def permitted_params
      params.permit(
        :date,
        :amount, 
        :code, 
        :orderid, 
        :transtype, 
        :sign, 
        :methodid, 
        :signtype, 
        :message, 
        :channelcode, 
        :channelinfo, 
        :channelmsg, 
        :merchantid, 
        :uqorderid, 
        :billamount, 
        :currency, 
        :state        
      )
    end
  end
end
