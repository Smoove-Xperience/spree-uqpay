class CheckPaymentStatusWorker
  include Sidekiq::Worker

  def perform(*args)
    sources = Spree::UqpayPaymentSource.where(state: "Paying")

    sources.each { |source| source.payment_method.check_payment_status(source) }
  end
end
