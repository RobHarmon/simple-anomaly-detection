WITH 
maxdate
AS (
	SELECT dateadd('day', -1, max(performance_date)) AS currentdate
	FROM employee_performance
	)
	,

session_perf
AS (
	SELECT performance_date
		,employee_id
		,sum(sessions_calls) AS calls
	FROM employee_performance, maxdate
	WHERE performance_date >= dateadd('day', -31, maxdate.currentdate)
	and performance_date <= maxdate.currentdate
	GROUP BY performance_date
		,employee_id
	)
	,

limits
AS (
	SELECT employee_id
		,coalesce(avg(calls) + STDDEV_SAMP(calls) / 16, 0) AS perfmax
		,coalesce(avg(calls) - STDDEV_SAMP(calls) / 16, 0) AS perfmin
	FROM session_perf, maxdate
	WHERE performance_date < maxdate.currentdate
	GROUP BY employee_id
	)
	,
	
	
current_perf
AS (
	SELECT employee_id
		,sum(CASE 
				WHEN performance_date = currentdate
					THEN calls
				ELSE 0
				END) AS calls
	FROM session_perf
		,maxdate
	GROUP BY employee_id
	)


SELECT current_perf.employee_id as entityid
	,current_perf.calls 
	,perfmax
	,perfmin
FROM current_perf
INNER JOIN limits ON limits.employee_id = current_perf.employee_id
WHERE calls < perfmin
	OR calls > perfmax
