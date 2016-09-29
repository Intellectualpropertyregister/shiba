class CrimeType < ActiveRecord::Base
    attr_accessor :crime_scale
    has_many :crime_type_descriptions
    has_and_belongs_to_many :cities
    before_save :set_exponential_value
    # fuzzily_searchable :offense

    # validates :offense, :offense_description, :score, presence: true
    # validates :offense, uniqueness: true

    def set_exponential_value
      if self.crime_scale.to_i == 0
        self.crime_weight = 0
      elsif self.crime_scale.to_i == 1
        self.crime_weight = 1
      else
        self.crime_weight = (2**(0.75 * self.crime_scale.to_f)).round(1)
      end
    end

    def fuzzy_match(match_string)
      edit_distance = Hotwater.ngram_distance(self.offense, match_string)
      ap "#{match_string} #{edit_distance}"
      if edit_distance >= 0.7
        return true
      end
      false
    end
end
