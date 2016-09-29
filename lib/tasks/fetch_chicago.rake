require 'csv'
require 'aws-sdk'

namespace :data do
  desc "Run the task to do initial fetch of data for Chicago"
  task :fetch_chicago => :environment do
    # crimedata_collection = []
    offset = 0
    limit = 5000
    running = true

    client = SODA::Client.new({:domain => "data.cityofchicago.org", :app_token => "vgVZvytbHU58HhOP4fYbuT3yA"})
    start_date = 52.weeks.ago.strftime('%F')
    end_date = 50.weeks.ago.strftime('%F')

    while running
      responses = client.get("ijzp-q8t2", {"$where" => "date > '2013-01-01' and date < '2013-12-31' offset #{offset}"})
      if responses.length == 0
          running = false
      else
        responses.each do |crimedata|
          # crime_type = CrimeType.find_by_fuzzy_offense(crimedata.primary_type).first # get the topmost match
          # ap crime_type
          # crime_type_string = nil
          # if crime_type.fuzzy_match(crimedata.primary_type)
          #   ap "match " + crime_type.offense + " " + crimedata.primary_type
          #   crime_type_string = crime_type.offense # assign crime type if is similar, nil otherwise
          # else
          #   "no match"
          # end
          c = CrimeData.create!(
                            address: crimedata.block,
                            city: "Chicago",
                            country: "US",
                            state: "Illinois",
                            case_number: crimedata.case_number,
                            crime_date: crimedata.date,
                            crime_src_type: "SODA",
                            crime_type: crimedata.primary_type,
                            latitude: crimedata.latitude,
                            longitude: crimedata.longitude,
                            beat: crimedata.beat,
                            x_coordinate: crimedata.x_coordinate,
                            y_coordinate: crimedata.y_coordinate,
                            block: crimedata.block,
                            primary_type: crimedata.primary_type,
                            location_description: crimedata.location_description,
                            iucr: crimedata.iucr,
                            domestic: crimedata.domestic,
                            ward: crimedata.ward,
                            arrest: crimedata.arrest,
                            description: crimedata.description,
                            fbi_code: crimedata.fbi_code,
                            year: crimedata.year,
                            community_area: crimedata.community_area,
                            district: crimedata.district,
                            )
          # ap crimedata
          # ap "----------------------------"
          # crimedata_collection << c
        end
        offset += limit
      end
    end
    # column_names = ["id", "address", "city", "country", "crime_case_id", "crime_date", "crime_src_type", "crime_type", "latitude", "longitude", "note", "source", "state", "case_number", "beat", "x_coordinate", "y_coordinate", "block", "primary_type", "location_description", "iucr", "domestic", "ward", "arrest", "description", "fbi_code", "year", "community_area", "district", "weighted_score", "created_at", "updated_at"]
    # @csv = CSV.open("tmp/chicago.csv", 'w')
    # CSV.generate do |csv|
    #   # @csv << column_names
    #   crimedata_collection.each do |product|
    #     @csv << product.attributes.values_at(*column_names)
    #   end
    # end
    # @csv.close

    # Aws.config[:credentials] = Aws::Credentials.new('AKIAJAWOKRGG7BMDDIMA', 'CNMpW/aOcOy3LanQWAnIYrkDY+bOUvpE3dF62cE4')
    # s3 = Aws::S3::Resource.new(region:'us-east-1')
    # obj = s3.bucket('redshift-loaders').object("tmp/chicago.csv")
    # obj.upload_file('tmp/chicago.csv')
  end


end