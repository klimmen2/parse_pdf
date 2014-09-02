class CreateClients < ActiveRecord::Migration
  def change
    create_table :clients do |t|
      t.integer :client_number, limit: 8  
      t.integer :bill_number, limit: 8	 

      t.timestamps
    end
  end
end
