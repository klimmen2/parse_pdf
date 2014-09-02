class Client < ActiveRecord::Base
	has_many :cellular_numbers, :dependent =>:destroy
	has_many :individual_details, :dependent =>:destroy
end
