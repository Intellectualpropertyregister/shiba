require 'spec_helper'

describe CrimeType do
  it "is valid with an offense, offense description and score" do
    crime_type = CrimeType.new(
      offense: 'Homicide',
      offense_description: 'First Degree Murder',
      score: 10
    )
    expect(crime_type).to be_valid
  end
  
  it "is invalid without an offense" do
    crime_type = CrimeType.new(
      offense_description: 'First Degree Murder',
      score: 10
    )
    expect(crime_type).to have(1).errors_on(:offense)
  end
  
  it "is invalid without an offense_description" do
    crime_type = CrimeType.new(
      offense: 'Homicide',
      score: 10
    )
    expect(crime_type).to have(1).errors_on(:offense_description)
  end

  it "is invalid without a score" do
    crime_type = CrimeType.new(
      offense: 'Homicide',
      offense_description: 'First Degree Murder'
    )
    expect(crime_type).to have(1).errors_on(:score)
  end

  it "must have a unique offense" do
    crime_type_a = CrimeType.create(
      offense: 'Homicide',
      offense_description: 'First Degree Murder',
      score: 10
    )
    crime_type_b = CrimeType.create(
      offense: 'Homicide',
      offense_description: 'First Degree Murder',
      score: 10
    )
    expect(crime_type_a).to be_valid
    expect(crime_type_b).to have(1).errors_on(:offense)
  end
  
  it "is able to fuzzy match and determine if two similar offense_descriptions are the same" do
    crime_type = CrimeType.new(
      offense: 'Homicide',
      offense_description: 'First Degree Murder',
      score: 10
    )
    is_match = crime_type.fuzzy_match('First Deg Murder')
    expect(is_match).to be_true
  end
  
  it "is able to fuzzy match and determine if two dissimilar offense_descriptions are unique offenses" do
    crime_type = CrimeType.new(
      offense: 'Homicide',
      offense_description: 'First Degree Murder',
      score: 10
    )
    is_match = crime_type.fuzzy_match('Sec Degree Murder')
    expect(is_match).to be_false
  end
end

# t.string :code
# t.string :offense
# t.string :offense_description
# t.boolean :is_index_crime
# t.integer :score
