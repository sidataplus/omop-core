select row_number() over(order by p.id) AS person_id,
       case Upper(p.gender)
         when 'M' then 8507
         when 'F' then 8532
       end AS gender_concept_id,
       Year(p.birthdate) AS year_of_birth,
       Month(p.birthdate) AS month_of_birth,
       Day(p.birthdate) AS day_of_birth,
       p.birthdate AS birth_datetime,
       case Upper(p.race)
         when 'WHITE' then 8527
         when 'BLACK' then 8516
         when 'ASIAN' then 8515
         else 0
       end AS race_concept_id,
       case
         when Upper(p.ethnicity) = 'HISPANIC' then 38003563
         when Upper(p.ethnicity) = 'NONHISPANIC' then 38003564
         else 0
       end AS ethnicity_concept_id,
       CAST(NULL AS INT) AS location_id,
       CAST(NULL AS INT) AS provider_id,
       CAST(NULL AS INT) AS care_site_id,
       p.id AS person_source_value,
       p.gender AS gender_source_value,
       0 AS gender_source_concept_id,
       p.race AS race_source_value,
       0 AS race_source_concept_id,
       p.ethnicity AS ethnicity_source_value,
       0 AS ethnicity_source_concept_id
from {{ source('synthea', 'patients') }} p
where  p.gender is not null