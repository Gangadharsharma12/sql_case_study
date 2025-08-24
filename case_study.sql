Scripts:
DROP TABLE IF EXISTS portal;

CREATE TABLE portal (
    portal_id INT PRIMARY KEY,
    portal_code VARCHAR(10),
    portal_name VARCHAR(50)
);

INSERT INTO portal (portal_id, portal_code, portal_name) VALUES
(1, 'MPR', 'My Perfect Resume'),
(2, 'RN',  'Resume Now'),
(3, 'ZETY','Zety'),
(4, 'LC',  'Live Career'),
(5, 'GEN', 'Resume Genius'),
(6, 'HELP','Resume Help');

DROP TABLE IF EXISTS user_registration;

CREATE TABLE user_registration (
    user_id BIGINT,
    portal_id INT,
    registration_datetime DATETIME,
    subscription_flag CHAR(1),
    subscription_datetime DATETIME NULL
);
delete from user_registration;
INSERT INTO user_registration VALUES
-- User 1001 registers on 2 portals, subscribes only on RN
(1001, 2, '2024-01-05 09:27:44', 'Y', '2024-01-06 10:00:00'),
-- User 1002 registers on ZETY and GEN, subscribes on both
(1002, 3, '2024-02-15 14:07:11', 'Y', '2024-02-15 15:30:00'),


-- User 1003 registers on RN and MPR, no subscriptions
(1003, 2, '2024-03-10 08:00:00', 'N', NULL),

-- User 1004 registers only once, subscribed
(1004, 4, '2024-05-19 09:45:00', 'Y', '2024-05-20 10:00:00'),

-- User 1005 registers only once, no subscription
(1005, 3, '2024-12-10 12:00:00', 'Y', '2024-12-15 12:00:00'),

-- User 1006 registers on 3 portals, mixed subscription
(1006, 1, '2024-07-01 11:00:00', 'Y', '2024-07-02 09:00:00'),


-- User 1007 registers on RN in Dec 2024, subscribes in Jan 2025 (boundary case)
(1007, 2, '2024-12-31 23:59:59', 'Y', '2025-01-01 00:15:00');

insert into user_registration values 
(1008, 4, '2024-03-15 23:59:59', 'N', NULL),
(1009, 2, '2025-01-15 23:59:59', 'Y', '2025-02-01 00:15:00');


insert into user_registration values
(1010, 3, '2024-02-10 14:00:00', 'N', NULL),
(1011, 5, '2024-03-01 00:00:00', 'Y', '2024-03-02 09:00:00'),
(1012, 1, '2024-04-01 09:30:00', 'N', NULL),
(1013, 2, '2024-07-05 14:00:00', 'N', NULL),
(1014, 5, '2024-08-10 18:00:00', 'Y', '2024-08-11 08:00:00'),
(1015, 2, '2024-01-20 23:59:59', 'Y', '2025-01-01 00:15:00');


DROP TABLE IF EXISTS resume_doc;

CREATE TABLE resume_doc (
    resume_id INT PRIMARY KEY,
    user_id BIGINT,
    date_created DATETIME,
    experience_years INT
);

INSERT INTO resume_doc VALUES
-- User 1001: Multiple resumes across portals
(2001, 1001, '2024-01-07 11:00:00', 2),
(2002, 1001, '2024-02-12 12:00:00', 3),

-- User 1002: Multiple resumes, high exp
(2003, 1002, '2024-02-16 10:00:00', 5),
(2004, 1002, '2024-03-05 12:00:00', 7),

-- User 1003: No resumes (edge case)

-- User 1004: Single resume, big experience
(2005, 1004, '2024-05-21 11:00:00', 12),

-- User 1005: Has resumes but no subscription
(2006, 1005, '2024-06-15 09:00:00', 0),
(2007, 1005, '2024-06-20 10:00:00', 1),

-- User 1006: Resumes before and after subscription
(2008, 1006, '2024-07-01 15:00:00', 8),
(2009, 1006, '2024-08-12 19:00:00', 9),

-- User 1007: Future-year resume
(2010, 1007, '2025-01-02 10:00:00', 20);

INSERT INTO resume_doc VALUES
-- User 1001: Multiple resumes across portals
(2011, 1001, '2025-01-07 11:00:00', 3),
(2012, 1001, '2025-01-08 11:00:00', 3);

-----------------------------------------------------------------------------------------------------------------------------------------------------------------

--1.what is the count of registrations every month on Resume now portal for 2024

select
  datename(month,registration_datetime) as month,
  count(*) as	Registrations
from portal p
join user_registration ur on p.portal_id = ur.portal_id
where ur.portal_id = 2 and year(registration_datetime) = 2024
group by  datename(month,registration_datetime)
order by  datename(month,registration_datetime)


--2.which portal has the highest subscription rate for users registerd in the last 30 days
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


--4.Create a list of users who subscribed in 2024 on the 'Zety' portal and get the experience_years on their first resume


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
