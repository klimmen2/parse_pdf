class HardWorkerrrrrrrrrrrrrrrrrrrrrrrrrrrrrrr
  include Sidekiq::Worker
  include SidekiqStatus::Worker
  sidekiq_options retry: false

  def perform(name_file)
  	sleep 30
  	p "HardWorker good"
  	sleep 30
  end
end