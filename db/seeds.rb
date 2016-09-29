# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

CrimeType.create(
[
  { offense: 'HOMICIDE', offense_description: 'Criminal Homicide', is_index_crime: true, score: 10 },
  { offense: 'FORCIBLE RAPE', offense_description: 'Forcible Rape', is_index_crime: true, score: 10 },
  { offense: 'ROBBERY', offense_description: 'Robbery', is_index_crime: true, score: 10 },
  { offense: 'AGGRAVATED ASSAULT', offense_description: 'Aggravated Assault', is_index_crime: true, score: 10 },
  { offense: 'BURGLARY', offense_description: 'Burglary', is_index_crime: true, score: 10 },
  { offense: 'LARCENY/THEFT', offense_description: 'Larceny/Theft', is_index_crime: true, score: 10 },
  { offense: 'MOTOR VEHICLE THEFT', offense_description: 'Motor Vehicle Theft', is_index_crime: true, score: 10 },
  { offense: 'ARSON', offense_description: 'Arson', is_index_crime: true, score: 10 },

  { offense: 'OTHER ASSAULTS', offense_description: 'Other Assaults', is_index_crime: false, score: 9 },
  { offense: 'FORGERY AND COUNTERFEITING', offense_description: 'Forgery and Counterfeiting', is_index_crime: false, score: 3 },
  { offense: 'FRAUD', offense_description: 'Fraud', is_index_crime: false, score: 0 },
  { offense: 'EMBLEZZLEMENT', offense_description: 'Embezzlement', is_index_crime: false, score: 0 },
  { offense: 'STOLEN PROPERTY: BUYING, RECEIVING, POSSESSING', offense_description: 'Stolen Property: Buying, Receiving, Possessing', is_index_crime: false, score: 4 },
  { offense: 'VANDALISM', offense_description: 'Vandalism', is_index_crime: false, score: 4 },
  { offense: 'WEAPONS: CARRYING, POSSESSING, ETC.', offense_description: 'Weapons: Carrying, Possessing, etc.', is_index_crime: false, score: 9 },
  { offense: 'Prostitution and Commercialized Vice', offense_description: 'Prostitution and Commercialized Vice', is_index_crime: false, score: 9 },
  { offense: 'Sex Offenses', offense_description: 'Sex Offenses', is_index_crime: false, score: 9 },
  { offense: 'Drug Abuse Violations', offense_description: 'Drug Abuse Violations', is_index_crime: false, score: 9 },
  { offense: 'Gambling', offense_description: 'Gambling', is_index_crime: false, score: 7 },
  { offense: 'Offenses Against the Family and Children', offense_description: 'Offenses Against the Family and Children', is_index_crime: false, score: 6 },
  { offense: 'Driving Under the Influence', offense_description: 'Driving Under the Influence', is_index_crime: false, score: 5 },
  { offense: 'Liquor Laws', offense_description: 'Liquor Laws', is_index_crime: false, score: 6 },
  { offense: 'Drunkenness', offense_description: 'Drunkenness', is_index_crime: false, score: 7 },
  { offense: 'Disorderly Conduct', offense_description: 'Disorderly Conduct', is_index_crime: false, score: 7 },
  { offense: 'Vagrancy', offense_description: 'Vagrancy', is_index_crime: false, score: 2 },
  { offense: 'All Other Offenses', offense_description: 'All Other Offenses', is_index_crime: false, score: 3 },
  { offense: 'Suspicion', offense_description: 'Suspicion', is_index_crime: false, score: 6 },
  { offense: 'Curfew and Loitering Laws', offense_description: 'Curfew and Loitering Laws', is_index_crime: false, score: 5 },
  { offense: 'Runaways', offense_description: 'Runaways', is_index_crime: false, score: 1 }
]
)