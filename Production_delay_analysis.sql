--1.Total Idle time per reason.
SELECT 
  reason,
  SUM(duration_minutes) AS total_idle_minutes
FROM machine_time_log
WHERE status = 'Idle'
GROUP BY reason
ORDER BY total_idle_minutes DESC;

--2.Compare the idle time according to date and day.
SELECT 
  log_date, TO_CHAR(log_date,'Dy') As day_name,
  SUM(duration_minutes) AS daily_idle_minutes
FROM machine_time_log
WHERE status = 'Idle'
GROUP BY log_date
ORDER BY log_date;

--3.ONN time vs Idle time of each machine

SELECT 
  Status,machine_id,
  COUNT(*) AS Entry_Count,
  SUM(Duration_Minutes) AS Total_Time_Minutes
FROM machine_time_log
GROUP BY 1,2;

--4.Hourly Idle Time Trend
SELECT 
  EXTRACT(HOUR FROM Start_Time) AS Hour_Of_Day,
  SUM(Duration_Minutes) AS Idle_Minutes
FROM machine_time_log
WHERE Status = 'Idle'
GROUP BY Hour_Of_Day
ORDER BY Hour_Of_Day;

--5.Find out top Idle Reasons per Machine
SELECT 
  Machine_ID,
  Reason,
  SUM(Duration_Minutes) AS Total_Idle_Minutes
FROM machine_time_log
WHERE Status = 'Idle'
GROUP BY Machine_ID, Reason
ORDER BY Machine_ID, Total_Idle_Minutes DESC;

--6.Find Standard Opeartion Time(SOT) for each idle reason per machine.
WITH ranked_times AS (
  SELECT 
    Machine_ID,
    Reason,
    Duration_Minutes,
    ROW_NUMBER() OVER (PARTITION BY Machine_ID, Reason ORDER BY Duration_Minutes ASC) AS rn
  FROM machine_time_log
  WHERE Status = 'Idle'
    AND Reason IS NOT NULL
)
SELECT 
  Machine_ID,
  Reason,
  ROUND(AVG(Duration_Minutes), 2) AS Estimated_SOT_Minutes
FROM ranked_times
WHERE rn <= 3
GROUP BY Machine_ID, Reason;

--7.Created estimated sot table.
CREATE TABLE estimated_sot AS
SELECT 
  Machine_ID,
  Reason,
  ROUND(AVG(Duration_Minutes), 2) AS Estimated_SOT_Minutes
FROM (
  SELECT 
    Machine_ID,
    Reason,
    Duration_Minutes,
    ROW_NUMBER() OVER (
      PARTITION BY Machine_ID, Reason 
      ORDER BY Duration_Minutes ASC
    ) AS rn
  FROM machine_time_log
  WHERE Status = 'Idle' AND Reason IS NOT NULL
) AS ranked
WHERE rn <= 3
GROUP BY Machine_ID, Reason;

--8.Compare Actual vs Estimated SOT and find efficiency in percentage of per day per reason.
SELECT 
  m.Log_Date,
  m.Machine_ID,
  m.Reason,
  m.Duration_Minutes AS Actual_Duration,
  e.Estimated_SOT_Minutes,
  m.Duration_Minutes - e.Estimated_SOT_Minutes AS Deviation,
  ROUND(e.Estimated_SOT_Minutes * 100.0 / m.Duration_Minutes, 2) AS Efficiency_Percent
FROM machine_time_log m
JOIN estimated_sot e 
  ON m.Machine_ID = e.Machine_ID AND m.Reason = e.Reason
WHERE m.Status = 'Idle';









