module Spree
    module UqpayCommon
      extend ActiveSupport::Concern
      
      included do        
        preference :uqpay_host, :string
        preference :uqpay_public_key, :string
        preference :uqpay_private_key, :string
        preference :uqpay_payment_merchant_id
        preference :uqpay_callback_url
        preference :uqpay_return_url

        PAYMENT_URL = "#{uqpay_host}/pay"
        CANCEL_URL = "#{uqpay_host}/cancel"
        REFUND_URL = "#{uqpay_host}/refund"
    
        def payment_data          
          {
            'merchant_id': uqpay_payemnt_merchant_id,
            'tranver_type': "pay",
            'orderid': "",
            'methodid': 2002,
            'amount': "0.01",
            'currency': "SGD",
            'transname': "TopUp",
            'quantity': "1",
            'returnurl': '',
            'callbackurl': uqpay_callback_url,
            'date': 1611741568985,
            'clienttype': "1",
            'clientip': "22",
            'signtype': "RSA",
          }
        end

        def cancel_data
          {
            'merchant_id': uqpay_payemnt_merchant_id,
            'tranver_type': "pay",
            'orderid': "",
            'uqorderid': "",            
            'amount': "0.01",
            'date': '',
            'callbackurl': uqpay_callback_url,
            'clienttype': '',
            'signtype': 'RSA'         
          }
        end

        def refund_data
          {
            'merchant_id': uqpay_payemnt_merchant_id,
            'tranver_type': "pay",
            'orderid': "",
            'uqorderid': "",            
            'amount': "0.01",
            'date': '',
            'callbackurl': uqpay_callback_url,
            'clienttype': '',
            'signtype': ''                      
          }
        end

        def create_signature(data)
          digest = OpenSSL::Digest::SHA256.new
          pkey = OpenSSL::PKey::RSA.new(2048)
          signature = pkey.sign(digest, data)
          
          signature
        end

        def verify_signature
          pub_key = pkey.public_key
          pub_key.verify(digest, signature, data) # => true
        end

        def pay
          resp = Faraday.post(PAYMENT_URL) do |req|
            req.headers['Accept'] = 'application/json'
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

            req.params = payment_data << {'sign': create_signature(payment_data)}
          end

          resp
        end

        def cancel
          resp = Faraday.post(CANCEL_URL) do |req|
            req.headers['Accept'] = 'application/json'
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

            req.params = cancel_data << {'sign': create_signature(cancel_data)}
          end

          resp
        end

        def refund
          resp = Faraday.post(PAYMENT_URL) do |req|
            req.headers['Accept'] = 'application/json'
            req.headers['Content-Type'] = 'application/x-www-form-urlencoded'

            req.params = refund_data << {'sign': create_signature(refund_data)}
          end

          resp
        end
      end
    end
  end
end
  