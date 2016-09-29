namespace :data do
  desc "Run the task to do initial fetch of data for SF"
  task :fetch_sf => :environment do
    client = SODA::Client.new({:domain => "data.sfgov.org", :app_token => "vgVZvytbHU58HhOP4fYbuT3yA"})
    start_date = 1.year.ago.to_formatted_s(:db)
    end_date = DateTime.now.to_formatted_s(:db)
    responses = client.get("tmnf-yvry", {"$where" => "date > '#{start_date}' and date < '#{end_date}'"})
    responses.each do |crimedata|
      CrimeData.create!(
                        address: crimedata.address,
                        city: "San Francisco",
                        country: "US",
                        state: "California",
                        case_number: crimedata.incidntnum,
                        crime_date: crimedata.date,
                        crime_src_type: "SODA",
                        crime_type: crimedata.category,
                        latitude: crimedata.x,
                        longitude: crimedata.y,
                        report_date: crimedata.date,
                        x_coordinate: crimedata.x,
                        y_coordinate: crimedata.y,
                        block: crimedata.block,
                        primary_type: crimedata.primary_type,
                        location_description: crimedata.location_description,
                        description: crimedata.descript,
                        beat: crimedata.pdid,
                        district: crimedata.pddistrict,
                        )
                        # p 'Created crime data entry'
    end
  end

end

# dayofweek
# time
# resolution