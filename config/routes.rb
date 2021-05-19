Spree::Core::Engine.routes.draw do
  resource :uqpay_payment_verifications, only: [:create]
end
