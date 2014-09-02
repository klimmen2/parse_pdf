class CreateIndividualDetails < ActiveRecord::Migration
  def change
    create_table :individual_details do |t|
      t.float :total_onths_savings
      t.float :total
      t.float :service_plan_name
      t.float :additional_local_airtime
      t.float :long_distance_charges
      t.float :data_and_other_services
      t.float :value_addded_services
      t.integer :client_id

      t.timestamps
    end
  end
end
