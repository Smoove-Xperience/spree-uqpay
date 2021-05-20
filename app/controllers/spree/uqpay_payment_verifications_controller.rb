module Spree
  class UqpayPaymentVerificationsController < BaseController    
    skip_before_action :verify_authenticity_token, only: [:create]

    def create            
      uqpay = Spree::PaymentMethod.find_by_type 'Spree::Gateway::UqpayChinaUnion'      
      
      if uqpay.verify_signature(permitted_params.to_h)                
        Rails.logger.info("Webhook called for Uqpay order #{permitted_params["orderid"]}")

        order_number, payment_number = split_payment_identifier permitted_params["orderid"]
        @payment = Spree::Payment.find_by_number payment_number
        order = Spree::Order.find_by_number order_number

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
       
        payment_source = Spree::UqpayPaymentSource.find_by(uqorderid: permitted_params["uqorderid"])
        payment_source.update(state: permitted_params["state"])
      
        head :ok
      end
    end

    private 

    def split_payment_identifier(payment_identifier)
      payment_identifier.split '-'
    end

    def transition_to_pending!
      @payment.pend! unless @payment.pending?
    end

    def transition_to_paid!
      return if @payment.completed?

      @payment.complete!

      return if @payment.order.completed?

      @payment.order.finalize!
      @payment.order.update_attributes(state: 'complete', completed_at: Time.now)     
    end

    def transition_to_failed!
      @payment.failure! unless @payment.failed?
      
      @payment.order.update(state: 'payment', completed_at: nil) unless @payment.order.paid_or_authorized?
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