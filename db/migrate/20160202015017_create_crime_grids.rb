class CreateCrimeGrids < ActiveRecord::Migration
  def change
    create_table :crime_grids do |t|
      t.references :city, index: true, foreign_key: true
      t.integer :row
      t.integer :col
      t.st_polygon :area, srid: 4326
      t.integer :daytime_safety_level
      t.integer :dark_safety_level

      t.timestamps null: false
    end
  end
end
