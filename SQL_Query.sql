-- create database patient_peadmission_risk;
use patient_peadmission_risk;
select * from diabetic_data; 

-- Exploration queries


-- 1 Count total encounters and total unique patients — how many patients appear more than once?

select count(encounter_id) as total_encounters , count(distinct patient_nbr) from  diabetic_data;

-- how many patients appear more than once?
SELECT
COUNT(*) AS patients_multiple_visits
FROM (
SELECT patient_nbr
FROM diabetic_data
GROUP BY patient_nbr
HAVING COUNT(encounter_id) > 1 -- only multi-visit patients
) t;

desc diabetic_data;

--  2 Count rows per readmitted value (<30, >30, NO) and calculate the % share of each
select readmitted ,
count(*) as value_count ,
concat(round((count(*)/(select count(*) from diabetic_data))*100,2),"%")  as per_of_share  
from diabetic_data
group by readmitted ;

-- 3 What are the top 10 most frequent primary diagnosis codes (diag_1) across all patients?
select diag_1 ,count(*) as diagnosis_code_frequency from diabetic_data
group by diag_1
order by  diagnosis_code_frequency desc 
limit 10;

--  4 What is the distribution of admission_type_id — count and % per type?
select admission_type_id,admission_type_label,count(*) as distribution_count , 
concat(round((count(*)/(select count(*) from diabetic_data  ))*100,2),"%")  as per_of_share   from diabetic_data
where admission_type_label <> "null"
group by admission_type_id,admission_type_label ;

-- 5 What is the min, max, and average time_in_hospital across all admissions?
select admission_type_label,
min(time_in_hospital) as minimun_time ,
max(time_in_hospital) maximum_time ,
round(avg(time_in_hospital) ,1) as average_time  
from diabetic_data
where admission_type_label <> "null"
group by admission_type_label;

-- 6  Which patient (patient_nbr) has the most encounters in the dataset — how many times were they admitted?
select patient_nbr , count(* ) as um_of_admissions from  diabetic_data
group by patient_nbr 
having um_of_admissions = (select  max(num_of_admissions) 
from(select  count(* ) as num_of_admissions from  diabetic_data group by patient_nbr ) t);

-- 7 Calculate the overall 30-day readmission rate: COUNT WHERE readmitted = "<30" ÷ total valid encounters × 100

select 
       concat(round((count(*)/(
       select count(*) from diabetic_data
       ))*100,2),"%")  as '30d_readmission_rate' 
from diabetic_data
where readmitted = "<30";

-- 8 Group by age — return readmission count and readmission rate % for each age bracket, sorted highest first
select age_group 
,sum(readmitted_30d) as readmitions_count ,
concat(round((sum(readmitted_30d)*100.0/count(*)),2 ),"%") as readmition_rate from diabetic_data
group by age_group
order by sum(readmitted_30d)*100.0/count(*) desc ;

-- 9 Group by gender — compare readmission rate % for Male vs Female patients
select gender ,
sum(readmitted_30d) as readmitions_count,
concat(round((sum(readmitted_30d)*100.0/count(*)),2 ),"%") as readmitions_rate
from diabetic_data
group by gender
order by sum(readmitted_30d)*100.0/count(*) desc ;

-- 10 Group by admission_type_id — which admission type (Emergency / Elective / Urgent) has the highest readmission rate?
select admission_type_id,admission_type_label ,
sum(readmitted_30d) as readmitions_count ,
concat(round((sum(readmitted_30d)*100)/count(*),2),"%")  as readmitions_rate
from diabetic_data
where admission_type_label <> "null"
group by admission_type_id,admission_type_label
order by (sum(readmitted_30d)*100)/count(*) desc ;

-- 11 Group by diag_1 — find the top 10 diagnosis codes with highest readmission rate (filter: min 100 encounters per diagnosis)
select  diag_1 ,
sum(readmitted_30d) as readmission_count,
concat(round(sum(readmitted_30d)*100.0/count(*),2),"%") as readmission_rate
from diabetic_data
group by diag_1
having count(*) >= 100
order by sum(readmitted_30d)*100.0/count(*) desc limit 10 ;

-- 12 Compare AVG time_in_hospital for readmitted (<30) vs not readmitted (NO) patients in a single query

select readmitted , round(avg(time_in_hospital),1) as  avg_time_in_hospital from diabetic_data
where readmitted NOT IN (">30")
group by readmitted
ORDER BY avg_time_in_hospital DESC ;

-- 13 Compare AVG num_medications for readmitted vs not readmitted patients — do readmitted patients get more medications?

select readmitted, AVG(num_medications) AS avg_num_medications from diabetic_data
where readmitted in (">30","No")
group by readmitted 
order by avg_num_medications desc ;

-- 14 Compare AVG number_inpatient (prior visits) for readmitted vs not readmitted patients

select readmitted, AVG(number_inpatient) AS avg_prior_visits from diabetic_data
where readmitted in (">30","No")
group by readmitted 
order by avg_prior_visits desc ;

-- 15 Group by race — calculate readmission rate % per race group. Are there disparities?
select race ,  COUNT(*) AS total_patients ,round(avg(readmitted_30d)*100,2) as readmission_rate 
from diabetic_data
group by race 
order by readmission_rate desc;

-- Advanced queries

-- 16 Assign risk tier per row using CASE WHEN: High if number_inpatient ≥ 3 AND time_in_hospital ≥ 7, 
-- Medium if either, Low if neither — then count patients per tier
select
	case 
		when(number_inpatient >= 3 and time_in_hospital  >= 7) then "High"
		when (number_inpatient >= 3 or time_in_hospital  >= 7) then "Medium"
		else "Low" 
	end as risk_tier ,
	count(*) as patients_count,
    concat(Round(count(*)/(select count(*) from diabetic_data)*100 ,2),"%") as percentage_share
from diabetic_data
group by  
		case 
		when(number_inpatient >= 3 and time_in_hospital  >= 7) then "High"
		when (number_inpatient >= 3 or time_in_hospital  >= 7) then "Medium"
		else "Low" 
	end
order by patients_count desc;

-- 17 Calculate 30-day readmission rate per risk tier — verify that High tier has the highest actual readmission rate
select
	case 
		when(number_inpatient >= 3 and time_in_hospital  >= 7) then "High"
		when (number_inpatient >= 3 or time_in_hospital  >= 7) then "Medium"
		else "Low" 
	end as risk_tier ,
	 avg(readmitted_30d) as readmission_rate
from diabetic_data
group by  
		case 
		when(number_inpatient >= 3 and time_in_hospital  >= 7) then "High"
		when (number_inpatient >= 3 or time_in_hospital  >= 7) then "Medium"
		else "Low" 
	end
order by readmission_rate desc;

--18 Group by insulin column values (No, Steady, Up, Down) — which insulin management approach has the lowest 30-day readmission rate?

select insulin,
avg(readmitted_30d) as readmission_rate
from diabetic_data
group by insulin
order by readmission_rate ;

--19  Group by number_diagnoses (1 through 9) — does readmission rate increase as number of diagnoses increases?
select number_diagnoses,avg(readmitted_30d) as readmission_rate from diabetic_data
group by number_diagnoses
order by readmission_rate desc;

--20 Find polypharmacy impact: compare readmission rate for patients with num_medications < 10 vs ≥ 10 using CASE WHEN
desc diabetic_data;
select 
case
when  num_medications <10 then "Less than 10"
else "More than 10"
end as num_medications_flag_label,
avg(readmitted_30d) as readmission_rate
 from diabetic_data
 
 group by 
case
	when  num_medications <10 then "Less than 10"
	else "More than 10"
end
order by readmission_rate desc;
desc diabetic_data;
--21 Which combination (age group + admission type) has the highest readmission rate?
select age_group , admission_type_label,
avg(readmitted_30d) as readmission_rate
from diabetic_data
group by age_group , admission_type_label
order by readmission_rate desc ;

-- 22Using a subquery, find all patients with more than 3 encounters 
-- what is their readmission rate vs single-visit patients?
SELECT 
    patient_group,
    AVG(readmitted_30d) AS readmission_rate
FROM (
    SELECT 
        patient_nbr,
        readmitted_30d,
        CASE
            WHEN patient_nbr IN (
                SELECT patient_nbr
                FROM diabetic_data
                GROUP BY patient_nbr
                HAVING COUNT(encounter_id) > 3
            )
            THEN 'More than 3 Encounters'
            WHEN patient_nbr IN (
                SELECT patient_nbr
                FROM diabetic_data
                GROUP BY patient_nbr
                HAVING COUNT(encounter_id) = 1
            )
            THEN 'Single Visit'
        END AS patient_group
    FROM diabetic_data
) AS patient_groups
WHERE patient_group IS NOT NULL
GROUP BY patient_group;

--23 Rank the top 15 highest-risk patients using ROW_NUMBER() ordered by number_inpatient DESC, time_in_hospital DESC 
-- return their age, gender, diagnosis, and readmitted value
desc diabetic_data;
select * from 
(select patient_nbr ,age,gender,diagnosis_category,readmitted_30d ,
row_number() over(order by number_inpatient desc , time_in_hospital desc  ) as rank_number from diabetic_data) t
where rank_number <= 15 ;

--24 creating a new final dataset for tableau
create table diabetic_final_data as 
select "encounter_id",
    "patient_nbr",
    "race",
    "gender",
    "age",
    "age_group",
    
    "time_in_hospital",
    "num_medications",
    "number_inpatient",
    "number_diagnoses",
    
    "diag_1",
    "diagnosis_category",
    
    "admission_type_label",
    
    "insulin",
    "insulin_flag",
    "insulin_flag_label",
    
    "risk_tier",
    "total_prior_visits",
    "polypharmacy_flag",
    "high_procedures_flag",
    
    "readmitted",
    "readmitted_30d",
    "readmission_label"
from diabetic_data;



