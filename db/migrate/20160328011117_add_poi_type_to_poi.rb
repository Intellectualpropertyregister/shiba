class AddPoiTypeToPoi < ActiveRecord::Migration
  def change
      add_column :pois, :poi_type, :string
  end
end
