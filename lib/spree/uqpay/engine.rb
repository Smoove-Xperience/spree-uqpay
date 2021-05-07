module Spree
  module Uqpay
    class Engine < ::Rails::Engine
      engine_name "spree-uqpay"

      isolate_namespace Spree::Uqpay

      initializer "spree.spree-uqpay.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Gateway::UqpayChinaUnion
      end
    end
  end
end
