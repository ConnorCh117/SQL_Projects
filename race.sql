SELECT *
FROM race;

--how many states were represented in the race 
select count(distinct state) as distinct_count
from race;

--what was the average time of men vs women 
select avg(Total_minutes) as avg_time, Gender  
from race 
group by Gender

--what were the youngest and eldest ages in the race 
select gender, min(age) as youngest, max(age) as eldest
from race 
group by gender;

--what was the average time for each age group 

with age_list as (
select *,
case 
	when age < 30 then '<30'
	when age < 40 then '30-39'
	when age < 50 then '40-49'
	when age < 60 then '50-59'
	else '60+' end as age_group
from race
)
select age_group, avg(total_minutes) as avg_min
from age_list
group by age_group;

--top 3 males and females
with ranking as (
select fullname, gender, total_minutes, 
ROW_NUMBER() over (partition by gender order by total_minutes) as ranking
from race ) 
select *
from ranking 
where ranking <=3;


