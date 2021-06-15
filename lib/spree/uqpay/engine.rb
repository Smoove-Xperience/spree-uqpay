module Spree
  module Uqpay
    class Engine < ::Rails::Engine
      require 'spree/core'
      
      engine_name "spree-uqpay"

      isolate_namespace Spree::Uqpay

      initializer "spree.spree-uqpay.payment_methods", :after => "spree.register.payment_methods" do |app|
        app.config.spree.payment_methods << Gateway::UqpayChinaUnion
      end

      def self.activate
        Spree::PermittedAttributes.source_attributes << :methodid
      end

      config.to_prepare &method(:activate).to_proc
    end
  end
end
