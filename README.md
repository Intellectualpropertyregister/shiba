# dataplatform
Safer Streets Internal Data Service Platform

### Setup
1. Make sure you have Postgres first. If not, install postgres: http://www.enterprisedb.com/products-services-training/pgdownload
2. Install `rvm`: http://rvm.io
3. In your terminal, go out of your project folder and then go back into the folder. A rvm warning should appear. Follow the steps in the rvm warning instructions to install the ruby version and create the dataplatform gemset
4. Run `bundle` to install all the gems
5. Run `rake db:create:all` to create all the necessary databases

For more information see `doc/` for further reading.

### API Methods

`GET http://localhost:3000/crime_data.json`

Params

```
q[city_cont]: Chicago
q[crime_date_gteq]: 2014-03-28
q[crime_date_lteq]: 2014-03-31
```


### SOCRATA Data Sources

#### Crime Reports
Chicago:
* https://data.cityofchicago.org/Public-Safety/Crimes-2001-to-present/ijzp-q8t2
* https://data.cityofchicago.org/resource/ijzp-q8t2.json

NY:
*
*

SF:
* https://data.sfgov.org/Public-Safety/SFPD-Incidents-from-1-January-2003/tmnf-yvry
* https://data.sfgov.org/resource/tmnf-yvry.json

LA:
* https://data.lacity.org/A-Safe-City/LAPD-Crime-and-Collision-Raw-Data-2014/eta5-h8qx
* https://data.lacity.org/resource/eta5-h8qx.json

#### Other useful data sources
Illinois Uniform Crime Reporting Codes (IUCR):
* https://data.cityofchicago.org/Public-Safety/Chicago-Police-Department-Illinois-Uniform-Crime-R/c7ck-438e
* https://data.cityofchicago.org/resource/c7ck-438e.json
