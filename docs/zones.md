# Zones
-

## Attributes

col_name | type | extras | pk/fk | indexed
--- | --- | --- | --- | --- | ---
id |INTEGER | NOT NULL DEFAULT | 🔑| indexed
name | CHARACTER VARYING | | | indexed GIST
area | GEOMETRY
area_type | CHARACTER VARYING
zone_type | CHARACTER VARYING
dark | BOOLEAN
daytime | BOOLEAN
city_id | INTEGER | | FKEY
created_at | TIMESTAMP WITHOUT TIME ZONE | NOT NULL
updated_at | TIMESTAMP WITHOUT TIME ZONE | NOT NULL

---

## Zone Type

A `zone_type` may be of the following:

  - `MODERATELY_SAFE` - The area should be considered safe regardless of reports, unless a severe event that causes the area to be `LOW_SAFETY` in a normal grid report
  - `MODERATE` - The area should be considered moderate regardless of reports
  - `LOW_SAFETY` - The area should be avoid as it is unsafe
  - `AVOID` - The area should be avoided at all costs

---

## Area Type

An area_type may be of the following:

- `AREA` - The area is a polygon encompassing a free form community area
- `STREET` - The area is a polygon encompassing part of or entirety of a specific street

---

## Behaviour

A zone may be...

- avoided for a specific time range only (e.g., avoid at dark only, but do not avoid for daytime)
- avoided as a whole area, or as a single street only
- if a zone is a street, and the street is `LOW_SAFETY`, but the grid that the street resides in is `MODERATELY_SAFE`, then the grid should remain `MODERATELY_SAFE`, but we try not to route users through the affected street.