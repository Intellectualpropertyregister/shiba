class CitiesCrimeTypeWeight < ActiveRecord::Base
	attr_accessor :crime_scale
  belongs_to :city
  belongs_to :crime_type
end
