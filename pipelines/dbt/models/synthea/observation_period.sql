

select row_number()over(order by start_date, person_id) AS observation_period_id,
       person_id AS person_id,
	   start_date AS observation_period_start_date,
	   end_date AS observation_period_end_date,
	   44814724 AS period_type_concept_id -- 44814724::https://athena.ohdsi.org/search-terms/terms/44814724
  from (
select p.person_id,
       min(e.start) start_date,
	   max(e.stop) end_date
  FROM {{ ref('person') }} p
  JOIN {{ source('synthea','encounters') }} e
    on p.person_source_value = e.patient
 group by p.person_id
       ) tmp