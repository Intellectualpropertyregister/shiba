class Poi < ActiveRecord::Base
    attr_accessor :latitude
    attr_accessor :longitude
    attr_accessor :city_name

    has_one :zone, dependent: :destroy
end
