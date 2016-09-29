namespace :data do
  desc "Run the task to do initial fetch of data for New York"
  task :fetch_ny => :environment do
    geojson = File.read('data/ny.geojson')
    responses = RGeo::GeoJSON.decode(geojson, :json_parser => :json)
    responses.each do |crimedata|
      CrimeData.create!(
                        city: "New York",
                        country: "US",
                        state: "New York",
                        crime_src_type: "geojson",
                        crime_type: crimedata['CR'],
                        latitude: crimedata.geometry.x,
                        longitude: crimedata.geometry.y,
                        x_coordinate: crimedata['X'],
                        y_coordinate: crimedata['Y'],
                        primary_type: crimedata['CR'],
                        year: crimedata['YR']
                        )
                        p 'Created crime data entry'
    end
  end

end
