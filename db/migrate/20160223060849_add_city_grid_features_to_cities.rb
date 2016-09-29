class AddCityGridFeaturesToCities < ActiveRecord::Migration
  def change
    add_column :cities, :grid_size, :float
    add_column :cities, :total_rows, :integer
    add_column :cities, :total_cols, :integer
  end
end
