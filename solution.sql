-- --------------- SETTING UP LOCAL DATABASE ------------------

CREATE DATABASE onetapp_assignment_q7;

USE onetapp_assignment_q7;

CREATE TABLE serial_detail (
	serial_detail_id int PRIMARY KEY,
    serial_number int,
    model varchar(10),
    manufacture_location varchar(20),
    manufacture_date DATE,
    customer VARCHAR(10),
    shipped_date DATE,
    warranty_expire_date DATE
);

CREATE TABLE rma_dimension (
	rma_dimension_id INT PRIMARY KEY,
    rma_number BIGINT,
    rma_priority VARCHAR(20),
	return_reason VARCHAR(20),
    service_type VARCHAR(20),
    serial_detail_id INT FOREIGN KEY REFERENCES serial_detail (serial_detail_id)
);

CREATE TABLE rma_status (
	id INT PRIMARY KEY,
    status VARCHAR(30),
    date DATE,
    rma_dimension_id INT FOREIGN KEY REFERENCES rma_dimension (rma_dimension_id)
);
-- Then I used data import/export wizard in MySQL Workbench to import data into above tables.



-- --------------- Q1. Stored procedure to return current status by inputting rma_number ------------------

DROP PROCEDURE IF EXISTS get_current_rma_status;

DELIMITER $$
CREATE PROCEDURE get_current_rma_status(IN var_rma_num INTEGER)
BEGIN
	SELECT status AS 'current_status'
	FROM rma_status
	WHERE rma_dimension_id = (
		SELECT rma_dimension_id
		FROM rma_dimension
		WHERE rma_number = var_rma_num
	)
	ORDER BY date DESC, id DESC -- latest status is the one which has highest value of `date` and `id`.
	LIMIT 1;
END$$
DELIMITER ;

/*
I selected some test cases manually from given datasets.

rma_dimension_id	rma_number				status

2203				998857321					Repair close
4968				998859298					Repair Open	
5233				998861055					Receipt
5389				998861219					Created
11317				998874999					Receipt
11599				998875634					Diagnosis Open
*/

CALL get_current_rma_status(998857321); -- expected output: Repair close
CALL get_current_rma_status(998859298); -- expected output: Repair Open
CALL get_current_rma_status(998861055); -- expected output: Receipt
CALL get_current_rma_status(998861219); -- expected output: Created
CALL get_current_rma_status(998874999); -- expected output: Receipt
CALL get_current_rma_status(998875634); -- expected output: Diagnosis open

-- ----------------------- Q2. Query to find no. of RMAs created in 2024 ----------------

WITH cte AS (
	SELECT *, LEFT(date, 4) AS "date_year"
	FROM rma_status
	WHERE LOWER(status) LIKE 'created'
)
SELECT date_year, COUNT(id)
FROM cte
WHERE date_year LIKE '2024'
GROUP BY date_year
;

-- ------------------- Q3. Query to count the RMAs created for each month of 2024 --------------

WITH cte AS (
	SELECT 
		*,
		YEAR(date) as "date_year",
		MONTH(date) as "month_num",
		MONTHNAME(date) as "month_name"
	FROM rma_status
)
SELECT month_num, month_name, count(id)
FROM cte
WHERE
	LOWER(status) LIKE 'created'
    AND date_year LIKE '2024'
group by month_num, month_name
order by month_num asc
;

-- --------------------- Q4. Query to get the number of RMAs grouped by their current status ----------------

with cte as (
	select *, row_number() over(partition by rma_dimension_id order by date desc, id desc) as "latest"
	from rma_status
)
select status, count(id)
from cte
where latest = 1
group by status
order by count(id) desc
;

-- ---------------- Q5. Get all RMAs that are currently stuck at a status for >5 days, excluding Repair Close -------------

with cte as (
	select
		*,
		row_number() over(partition by rma_dimension_id order by date desc, id desc) as "latest",
        datediff(CURRENT_DATE(), date) as "days_stuck"
	from rma_status
)
select *
from cte
where
	latest = 1
	and lower(status) not like 'repair close'
    and days_stuck > 5
;