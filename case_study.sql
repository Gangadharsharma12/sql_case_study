--1.what is the count of registrations every month on Resume now portal for 2024

select
  datename(month,registration_datetime) as month,
  count(*) as	Registrations
from portal p
join user_registration ur on p.portal_id = ur.portal_id
where ur.portal_id = 2 and year(registration_datetime) = 2024
group by  datename(month,registration_datetime)
order by  datename(month,registration_datetime)


--which portal has the highest subscription rate for users registerd in the last 30 days
--subscription_rate = total_subscriptions / total_registrations

with cte as(
select
    portal_name,
	count(*) as total_registration,
	sum (case when subscription_flag = 'y' then 1 else 0 end) as total_subscription
from portal p
join user_registration ur on p.portal_id = ur.portal_id
group by portal_name
)

select
  top 1
  portal_name,
  round((total_subscription * 100.0 / total_registration),2) as subscription_rate
from cte


--3 How many registered users create less than 3 resumes
select
  count(*) as less_than_3_resume_created_users
from (
		select
		   ur.user_id,
		   count(r.resume_id) as cnt
		from user_registration ur
		left join resume_doc r on ur.user_id = r.user_id
		group by ur.user_id
		having count(r.resume_id) < 3
)aa





with cte as(
select
  portal_name,
  user_id
from portal p
join user_registration ur on p.portal_id = ur.portal_id
where (portal_name = 'Zety' and ur.portal_id = 3) and (subscription_flag = 'Y' and year(registration_datetime) = 2024)
),

cte1 as(
select
   user_id,
   experience_years,
   dense_rank() over (partition by user_id order by date_created) as creation_date
from resume_doc
where user_id in (select user_id from cte)
)

select
   user_id,
   experience_years
from cte1
where creation_date = 1 and experience_years > 0