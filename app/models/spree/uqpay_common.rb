module Spree
  module UqpayCommon
    extend ActiveSupport::Concern
    
    included do        
      preference :uqpay_host, :string        
      preference :uqpay_private_key, :string
      preference :uqpay_payment_merchant_id, :string
      preference :uqpay_callback_url, :string
      preference :uqpay_return_url, :string

      PAYMENT_URL = "#{uqpay_host}/pay"
      CANCEL_URL = "#{uqpay_host}/cancel"
      REFUND_URL = "#{uqpay_host}/refund"
  
      def payment_data(purchase_params)          
        data = {
          'merchant_id': uqpay_payemnt_merchant_id,
          'transtype': "pay",
          # 'orderid': "",
          # 'methodid': 2001,
          # 'amount': "0.01",
          # 'currency': "SGD",
          'transname': "Purchase - #{purchase_params[:orderid]}",
          # 'quantity': "1",
          'returnurl': uqpay_return_url,
          'callbackurl': uqpay_callback_url,
          'date': Time.zone.now.to_i,
          'clienttype': "1",
          'clientip': request.remote_ip,
          'signtype': "RSA",
        }.merge(purchase_params)
      end

      def cancel_data(cancel_params)
        data = {
          'merchant_id': uqpay_payemnt_merchant_id,
          'transtype': "cancel",
          # 'orderid': "",
          # 'uqorderid': "",            
          # 'amount': "0.01",
          'callbackurl': uqpay_callback_url,
          'date': Time.zone.now.to_i,            
          'clienttype': '1',
          'signtype': 'RSA'         
        }.merge(cancel_params)
      end

      def refund_data(refund_params)
        {
          'merchant_id': uqpay_payemnt_merchant_id,
          'transtype': "refund",
          # 'orderid': "",
          # 'uqorderid': "",            
          # 'amount': "0.01",
          'date': Time.zone.now.to_i,
          'callbackurl': uqpay_callback_url,
          'clienttype': '1',
          'signtype': 'RSA'                      
        }.merge(refund_params)
      end

      def create_signature(data)
        data = data.sort_by { |key| key }.reverse.to_h

        digest = OpenSSL::Digest::SHA1.new
        pkey = OpenSSL::PKey::RSA.new uqpay_private_key
        signature = pkey.sign(digest, data)
        
        Base64.strict_encode64(signature)
      end

      def verify_signature(data)
        data = data.sort_by { |key| key }.reverse.to_h

        digest = OpenSSL::Digest::SHA1.new
        pkey = OpenSSL::PKey::RSA.new uqpay_private_key
        pub_key = pkey.public_key
        
        pub_key.verify(digest, signature, data)
      end

      def pay
        send(PAYMENT_URL, payment_data)          
      end

      def cancel
        send(CANCEL_URL, cancel_data)
      end

      def refund
        send(REFUND_URL, refund_data)
      end

      private
      def send(url, data)
        resp = Faraday.post(url) do |req|
          req.headers['Accept'] = 'application/json'
          req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

          req.params = data.merge{'sign': create_signature(data)}
        end

        resp
      end
    end
  end
end
  