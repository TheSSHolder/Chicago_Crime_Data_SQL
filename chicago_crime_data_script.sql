--the usual--
SELECT  *
FROM `bigquery-public-data.chicago_crime.crime`;

--checking if dupes present--
select
count(distinct(case_number)) as Total_disctinct_cases,
count(case_number) as Total_cases
from `bigquery-public-data.chicago_crime.crime`;

--checking unique key for dupes--
select
count(distinct(unique_key)) as total_distinct_keys,
count(unique_key) as total_keys
from`bigquery-public-data.chicago_crime.crime`;

--pulling the duplicate case numbers to examine them--
select * 
from `bigquery-public-data.chicago_crime.crime`
where case_number in (
  select case_number 
  from `bigquery-public-data.chicago_crime.crime`
  group by case_number
  having count(case_number) > 1
) 
order by case_number;

--keeping what is necessary--
create table chicago_criminal_data.chicago_crime_v2 as
select distinct(case_number),block, date, primary_type,description, location_description,arrest, domestic
from `bigquery-public-data.chicago_crime.crime`;


--querying to observe columns with null values--
SELECT  *
FROM chicago_criminal_data.chicago_crime_v3
where 
case_number is null 
or primary_type is null
or block is null
or date is null
or description is null
or location_description is null
or arrest is null
or domestic is null;

--cleaning null values--
delete from `coursera-380912.chicago_criminal_data.chicago_crime_v2`
where case_number is null;

create or replace table chicago_criminal_data.chicago_crime_v3 as(
select case_number,primary_type,block,date,description,ifnull(location_description,"Unknown") as new_location_description,arrest,domestic
from `coursera-380912.chicago_criminal_data.chicago_crime_v2`);

select *
from `coursera-380912.chicago_criminal_data.chicago_crime_v3`
where case_number is null or new_location_description is null;

--separating datetime into date and time--
create table chicago_criminal_data.chicago_crime_V4 as
select case_number,primary_type,block,
extract(date from date) as date,
extract(time from date) as time,
description,new_location_description,arrest,domestic
from `chicago_criminal_data.chicago_crime_v3`;

select *
from `coursera-380912.chicago_criminal_data.chicago_crime_V4`;

--Preparing to split the Block column into a cleaner format by obseriving the fields in the Block column further--
SELECT length_of_array,
count (length_of_array) as Observations
from(select
array_length(split(block," ")) as length_of_array
from `coursera-380912.chicago_criminal_data.chicago_crime_V4`)
group by length_of_array
order by length_of_array;

--some values of the "block" column do not have enough elements in the array to support offset(3)--

SELECT
    case_number,
    primary_type,
    date,
    time,
    description,
    new_location_description,
    arrest,
    domestic,
    CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 2 THEN split(block, " ")[OFFSET(1)] END AS cardinal_section,
    CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 3 THEN split(block, " ")[OFFSET(2)] END AS Address,
    CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 4 THEN split(block, " ")[OFFSET(3)] else "None" END AS Address2
FROM `coursera-380912.chicago_criminal_data.chicago_crime_V4`;

--Creating table with fully cleaned data--

create or replace table chicago_criminal_data.final_chicago_crime_data as 
select
case_number,primary_type,date,time,description,new_location_description,
CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 2 THEN split(block, " ")[OFFSET(1)] END AS cardinal_section,
CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 3 THEN split(block, " ")[OFFSET(2)] END AS Address,
CASE WHEN ARRAY_LENGTH(split(block, " ")) >= 4 THEN split(block, " ")[OFFSET(3)] else "None" END AS Address2,
arrest,domestic
from `coursera-380912.chicago_criminal_data.chicago_crime_V4`;
