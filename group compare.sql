WITH 
reference_date  
--this establishes the day for which we want to analyze performance 
--today is still happening, so the last complete day we can analyze is yesterday
--this could be modified to run hourly instead of daily, depending on the metric
AS (
	SELECT date_add('day', 1, max(performance_date)) AS reference_date
	FROM employee_performance
	)
	
,
session_perf
--this finds the aggregate of performance over the past 7 days for the cohortby member
--in this case, we're looking at the prior week's performance, we can change our granularity 
--by adjusting the number of days in the where clause
AS (
	SELECT 
		employee_id
		,sum(coalesce(sessions_calls, 0)) AS calls
	FROM employee_performance, reference_date
	WHERE  performance_date >= date_add('day', -7, reference_date.reference_date)
        and    performance_date <= reference_date.reference_date
	GROUP BY employee_id
	)
	
,limits
--this cuts previous performance down and sets the limits of expected performance
--we look at the prior week's performance, find the mean +/- a quarter standard deviation
--this is a quarter standard deviation is a bit tight for most uses, half is more common
--and should be adjusted to meet your business
as (
SELECT 
		coalesce(avg(calls) + STDDEV_SAMP(calls) / 4, 0) AS perfmax
		,coalesce(avg(calls) - STDDEV_SAMP(calls) / 4, 0) AS perfmin
	FROM session_perf
	
)

--last, we find all members of the cohortwho's performance yesterday is "abnormal"
--meaning it fell outside either the positive or negative limits of the cohoart's
--expected limits

select * from session_perf
, limits
where perfmax < calls or perfmin > calls



