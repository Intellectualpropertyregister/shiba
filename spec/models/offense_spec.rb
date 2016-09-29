require 'spec_helper'

describe CrimeType do
  before(:each) do
    @crime_type =  CrimeType.create(
      offense: "CRIMINAL HOMICIDE",
      offense_description: "Criminal Homicide",
      is_index_crime: true,
      score: 10
    )
    @crime_type.update_fuzzy_offense!
  end

  it "is valid with an description, score and crime type" do
    offense = Offense.new(
      description: 'Homicide',
      crime_type_id: @crime_type.id,
      score: 10
    )
    expect(offense).to be_valid
  end
  
  it "is invalid without a description" do
    offense = Offense.new(
      crime_type_id: @crime_type.id,
      score: 10
    )
    expect(offense).to have(1).errors_on(:description)
  end
  
end

# t.string :description
# t.integer :score
# t.boolean :needs_validation
# t.references :crime_type
