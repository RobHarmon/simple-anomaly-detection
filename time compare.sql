WITH 
reference_date
--this establishes the day for which we want to analyze performance 
--today is still happening, so the last complete day we can analyze is yesterday
--this could be modified to run hourly instead of daily, depending on the metric
AS (
	SELECT date_add('day', -1, max(performance_date)) AS reference_date
	FROM employee_performance
	)
	,

session_perf
--We're looking for the past performance of an individual 
--over the past 30 days.  It's important that the time window is long enough to
--establish a solid trend of performance. 
AS (
	SELECT performance_date
		,employee_id
		,sum(sessions_calls) AS calls
	FROM employee_performance, reference_date
	WHERE performance_date >= date_add('day', -31, reference_date.reference_date)
	and performance_date <= reference_date.reference_date
	GROUP BY performance_date
		,employee_id
	)
	,

limits
--We then need to establish what "normal" is for the individual.  We do this by 
--finding a quarter standard deviation from the mean of the individual's performance
--history.
AS (
	SELECT employee_id
		,coalesce(avg(calls) + STDDEV_SAMP(calls) / 4, 0) AS perfmax
		,coalesce(avg(calls) - STDDEV_SAMP(calls) / 4, 0) AS perfmin
	FROM session_perf, reference_date
	WHERE performance_date < reference_date.reference_date
	GROUP BY employee_id
	)
	,
	
	
current_perf
--We find the individual's performance yesterday.  This is what we're analyzing.
AS (
	SELECT employee_id
		,sum(CASE 
				WHEN performance_date = reference_date
					THEN calls
				ELSE 0
				END) AS calls
	FROM session_perf
		,reference_date
	GROUP BY employee_id
	)

--If that individual's performance is below or above expected, we need to know about it
--If it's above, we need to learn why and teach the rest of the team.  If it's below, 
--we need to take the lessons we've learned from those exceeding and teach them.

SELECT current_perf.employee_id as entityid
	,current_perf.calls 
	,perfmax
	,perfmin
FROM current_perf
INNER JOIN limits ON limits.employee_id = current_perf.employee_id
WHERE calls < perfmin
	OR calls > perfmax
