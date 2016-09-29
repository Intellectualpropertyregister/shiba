class CreateZones < ActiveRecord::Migration
  def change
    create_table :zones do |t|
      t.string :name
      t.geometry :area, limit: {:type=>"geometry"}
      t.string :zone_type
      t.belongs_to :city, index: true, foreign_key: true

      t.timestamps null: false
    end
    add_index :zones, :area, using: :gist
  end
end
