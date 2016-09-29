# DataPlatform (Shiba)
DataPlatform is an Data Analysis tool and it helps to generate all the reports required for SaferStreets.
Following are the features in DataPlatform:
* Edit & created
    * Crime Data
    * Crime Type
    * Crime Type Weight based on Cities
    * Crime Type Descriptions
    * Worker (Create only)
    * Point of Interest (POI)
* Get notification for spike in crime and anomalies crime clustered in a particular grid

## Overview
DataPlatform is mainly to generate reports for SaferStreets with some core libraries:
* [sidekiq](https://github.com/mperham/sidekiq) background processing
* [sidekiq-cron](https://github.com/ondrejbartas/sidekiq-cron) scheduler / cron for sidekiq jobs
* [kiba](https://github.com/thbar/kiba) lightweight ETL for ruby
* [redis](http://redis.io/) Redis Cache for storing reports

DataPlatform has two main components:
* [Web app](http://shiba.nest.insider): User can generate reports by invoking the workers from the web app
* Workers: Universal workers to generate crime reports, safety reports, analysis and etc. for all cities

## Workers
Workers are the cron job that will generate the reports. The following workers are listed in sequence:
1. `city_crime_matrix.rb`
    * Generate grid for a city
    * Generate crime report (based on grid)
    * Generate user rating report
    * Generate crime trend report
    * Generate safety report
    * Generate point of interest list
    * Generate annual average of crime
    * Generate annual crime report
    * Generate annual safety report
    * Generate annual crime trend report
2. `delta_worker`
    * Generate delta reports
3. `spike_worker`
    * Compare the current crime data with delta reports to check the spike status
4. `crime_visualize_worker`
    * Generate grid visualization with coordinates and color code (based on the safety report)
5. `postgis_grid_worker`

6. `route_rating_worker`
7. `poi_analyze_worker`
