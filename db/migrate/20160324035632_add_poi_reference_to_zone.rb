class AddPoiReferenceToZone < ActiveRecord::Migration
  def change
      add_column :zones, :poi_id, :integer
      add_index :zones, :poi_id
  end
end
