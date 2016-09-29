class AddAreaTypeDarkAndDaytimetoZones < ActiveRecord::Migration
  def change
      add_column :zones, :area_types, :string
      add_column :zones, :dark, :boolean, default: true
      add_column :zones, :daytime, :boolean, default: true
  end
end
