class CreateCityCrimeWeights < ActiveRecord::Migration
  def change
    create_table :cities_crime_type_weights do |t|
    	t.timestamps null: false
    	t.belongs_to :city, index: true
    	t.belongs_to :crime_type, index: true
    	t.float :crime_weight
    end
  end
end
