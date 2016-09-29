namespace :data do
  desc "Run the task to do initial fetch of crime offenses"
  task :get_offenses => :environment do
    client = SODA::Client.new({:domain => "data.cityofchicago.org", :app_token => "vgVZvytbHU58HhOP4fYbuT3yA"})
    responses = client.get("c7ck-438e")
    responses.each do |offense|
      Offense.create!(
                        description: offense.secondary_description,
                        score: "Chicago",
                        needs_validation: true,
                        crime_type: nil
                        )
                        p 'Created offense: #{offense}'
    end
  end

end
#
# iucr
# primary_description
#
# index_code
#
# t.string :
# t.integer :score
# t.boolean :needs_validation
# t.references :crime_type
