WITH 
reference_date
AS (
	SELECT date_add('day', 1, max(performance_date)) AS currentdate
	FROM employee_performance
	)
	
,
session_perf
AS (
	SELECT 
		employee_id
		,sum(coalesce(sessions_calls, 0)) AS calls
	FROM employee_performance, reference_date
	WHERE  performance_date >= dateadd('day', -7, reference_date.currentdate)
        and    performance_date <= reference_date.currentdate
	GROUP BY employee_id
	)
	
,limits
as (
SELECT 
		coalesce(avg(calls) + STDDEV_SAMP(calls) / 4, 0) AS perfmax
		,coalesce(avg(calls) - STDDEV_SAMP(calls) / 4, 0) AS perfmin
	FROM session_perf
	
)
select * from session_perf
, limits
where perfmax < calls or perfmin > calls



