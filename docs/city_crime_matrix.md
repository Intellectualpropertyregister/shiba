# CityCrimeMatrix
The foundation of the all reports
* Redis is required to store all the data

## What this worker does
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

## Generate Grid
This method will generate `city_features` JSON Object and `crime_coordinates` for each grid

### Visualization of Grid
```
                            Column
                        _____ _____ _____ _____ _____ _____ _____* North East (Latitude, Longitude)        
                       | 0,0 | 0,1 | 0,2 | 0,3 | 0,4 | 0,5 | ... |
                       |_____|_____|_____|_____|_____|_____| ... |
            Row        | 1,0 | 1,1 | 1,2 | 1,3 | 1,4 | 1,5 | ... |
                       |_____|_____|_____|_____|_____|_____| ... |
                       |  .  |  .  |  .  |  .  |  .  |  .  | ... |
                       |  .  |  .  |  .  |  .  |  .  |  .  | ... |
                       |  .  |  .  |  .  |  .  |  .  |  .  | ... |
                       |_____|_____|_____|_____|_____|_____| ... |
                       | ... |10,01|10,02|10,03|10,04|10,05|10,06|
                       |_____|_____|_____|_____|_____|_____|_____|
                       *
South West (Latitude,Longitude)                   
```
- 0,0 -> Row 0, Column 0
- 10,01 -> Row 10, Column 01
