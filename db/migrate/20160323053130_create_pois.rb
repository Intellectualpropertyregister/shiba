class CreatePois < ActiveRecord::Migration
  def change
    create_table :pois do |t|
        t.string :name
        t.references :city
        t.geometry :location
        t.string :poi_safety_level
        t.string :address
        t.timestamps null: false
    end
  end
end
