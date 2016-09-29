# Shiba Workers
-

Shiba uses RabbitMQ to receive push message from `munchkin` & uses `redis` to get value,

### Gems required

```
gem 'bunny', '>= 2.2.1'
gem 'aws-sdk', '~> 2'
```

### Channel Queue Name

`etl_completion_queue`

### Message format

`soda_1_delta (source_cityId_worktype)`

### Send Message via local

`rabbitmqadmin publish exchange=amq.default routing_key=etl_completion_queue payload="soda_1_delta"`

---

## Calculate Delta Worker

### Flow of calculating delta

Get current report (2 weeks) & historical report (previous 2 weeks) from redis

### Formula used to calculate delta
```
crime_current = number of crime type in current report
crime_history = number of crime type in history
       
crime type delta = crime_current / (crime_current + crime_history)
```

After calculating the delta report, it will get to update inside crime grid report based on the row & col.