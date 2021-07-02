module Spree
  module UqpayCommon
    extend ActiveSupport::Concern
    
    included do
      attr_accessor :uqpay_host, :uqpay_private_key, :uqpay_merchant_id, :uqpay_callback_url, :uqpay_return_url, :uqpay_client_ip

      preference :uqpay_host, :string        
      preference :uqpay_private_key, :text
      preference :uqpay_public_key, :text
      preference :uqpay_merchant_id, :string
      preference :uqpay_callback_url, :string
      preference :uqpay_return_url, :string
      preference :uqpay_client_ip, :string

      def uqpay_host
        ENV['UQPAY_HOST'] || preferred_uqpay_host
      end

      def uqpay_private_key
        ENV['UQPAY_PRIVATE_KEY'] || preferred_uqpay_private_key
      end

      def uqpay_public_key
        ENV['UQPAY_PUBLIC_KEY'] || preferred_uqpay_public_key
      end

      def uqpay_merchant_id
        ENV['UQPAY_MERCHANT_ID'] || preferred_uqpay_merchant_id
      end

      def uqpay_callback_url
        ENV['UQPAY_CALLBACK_URL'] || preferred_uqpay_callback_url
      end

      def uqpay_return_url
        ENV['UQPAY_RETURN_URL'] || preferred_uqpay_return_url
      end

      def uqpay_client_ip
        ENV['UQPAY_CLIENT_IP'] || preferred_uqpay_client_ip
      end

      def payment_source_class
        Spree::UqpayPaymentSource
      end

      def create_signature(data)
        data = data.sort_by { |key| key }.to_h
        encoded_data = data.to_a.map { |item| item.join "=" }.join "&"
                    
        digest = OpenSSL::Digest::SHA1.new
        pkey = OpenSSL::PKey::RSA.new uqpay_private_key
        signature = pkey.sign(digest, encoded_data)
        
        Base64.strict_encode64(signature)
      end

      def verify_signature(data)        
        signature = Base64.decode64(data["sign"])
        
        encoded_data = data.except("signtype", "sign")
        
        encoded_data = encoded_data.sort_by { |key| key }.to_h

        encoded_data = encoded_data.to_a.map { |item| item.join "=" }.join "&"
        
        digest = OpenSSL::Digest::SHA1.new
        pkey = OpenSSL::PKey::RSA.new uqpay_public_key
        pub_key = pkey.public_key

        pub_key.verify(digest, signature, encoded_data)
      end

      def pay(params)
        payment_data = {
          merchantid: uqpay_merchant_id,
          transtype: "pay",
          transname: "Purchase - #{params[:orderid]}",
          returnurl: uqpay_return_url,
          callbackurl: uqpay_callback_url,
          date: Time.zone.now.to_i,
          clienttype: "1",
          clientip: uqpay_client_ip,
          quantity: "1",
        }.merge(params)

        make_request("#{uqpay_host}/pay", payment_data)          
      end

      def cancel(params)
        cancel_data = {
          'merchantid': uqpay_merchant_id,
          'transtype': "cancel",
          'callbackurl': uqpay_callback_url,         
          'clienttype': '1',
        }.merge(params)
  
        make_request("#{uqpay_host}/cancel", cancel_data)
      end

      def refund(params)
        refund_data = {
          'merchantid': uqpay_merchant_id,
          'transtype': "refund",
          'callbackurl': uqpay_callback_url,
          'clienttype': '1',
        }.merge(params)

        make_request("#{uqpay_host}/refund", refund_data)
      end

      def check_payment_status(source)
        if source.uqorderid.present? && source.date.to_i <= (60.minutes.ago.to_i * 1000)
          query_data = {
            merchantid: uqpay_merchant_id,
            transtype: "query",
            uqorderid: source.uqorderid,
            date: source.date
          }

          response = make_request("#{uqpay_host}/query", query_data)

          if response.status == 200
            parsed_body = JSON.parse(response.body)
            @payment = source.payment

            case parsed_body["state"]
              when "Success"
                transition_to_paid!      
              when "Closed"          
                transition_to_failed!
              when "Failed"          
                transition_to_failed!
            end

            source.update(state: parsed_body["state"])
          end
        end
      end

      private

      def make_request(url, data)
        data = data.merge({
          signtype: "RSA",
          sign: create_signature(data)
        })
        
        resp = Faraday.post(url, data) do |req|
          req.headers['Accept'] = 'application/json'
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'
        end

        resp
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
    end
  end
end
