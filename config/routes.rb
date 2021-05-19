Spree::Core::Engine.routes.draw do
    resource :uqpay_payment_verification, only: [:create]
end
