class CreateCellularNumbers < ActiveRecord::Migration
  def change
    create_table :cellular_numbers do |t|
      t.string :user
      t.float :service_plan_price
      t.float :additional_local_airtime
      t.float :ld_and_roaming_charges
      t.float :data_voice_and_other
      t.float :other_frees
      t.float :gst
      t.float :subtotal
      t.float :total
      t.integer :client_id

      t.timestamps
    end
  end
end
