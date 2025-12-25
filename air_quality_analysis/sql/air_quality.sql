CREATE DATABASE air_quality_db;

USE air_quality_db;

CREATE TABLE aqi_data (
    id INT AUTO_INCREMENT PRIMARY KEY,
    state_name VARCHAR(255),
    county_name VARCHAR(255),
    state_code VARCHAR(2),
    county_code VARCHAR(3),
    date DATE,
    aqi INT,
    category VARCHAR(50),
    defining_parameter VARCHAR(255),
    defining_site VARCHAR(255),
    num_sites_reporting INT
);

USE air_quality_db;

-- 10 counties with the worst decline
WITH aqi_1999 AS (
    SELECT 
        state_name, 
        county_name, 
        AVG(aqi) AS avg_aqi_1999
    FROM aqi_data
    WHERE YEAR(date) = 1999
    GROUP BY state_name, county_name
),
aqi_2023 AS (
    SELECT 
        state_name, 
        county_name, 
        AVG(aqi) AS avg_aqi_2023
    FROM aqi_data
    WHERE YEAR(date) = 2023
    GROUP BY state_name, county_name
)
SELECT 
    a1999.state_name,
    a1999.county_name,
    a1999.avg_aqi_1999,
    a2023.avg_aqi_2023,
    (a2023.avg_aqi_2023 - a1999.avg_aqi_1999) AS aqi_increase
FROM aqi_1999 a1999
JOIN aqi_2023 a2023 
    ON a1999.state_name = a2023.state_name 
    AND a1999.county_name = a2023.county_name
ORDER BY aqi_increase DESC
LIMIT 10;

-- Average AQI by Year and Season
SELECT
   CONCAT(season, ' ', year) AS season_year,
   avg_aqi
FROM (
   SELECT
       YEAR(date) AS year,
       CASE
           WHEN MONTH(date) IN (12, 1, 2) THEN 'Winter'
           WHEN MONTH(date) IN (3, 4, 5) THEN 'Spring'
           WHEN MONTH(date) IN (6, 7, 8) THEN 'Summer'
           ELSE 'Fall'
       END AS season,
       ROUND(AVG(aqi), 2) AS avg_aqi
   FROM aqi_data
   GROUP BY year, season
) AS seasonal_data
ORDER BY year,
   CASE season
       WHEN 'Winter' THEN 1
       WHEN 'Spring' THEN 2
       WHEN 'Summer' THEN 3
       ELSE 4
   END;
    
-- Top 10 Locations with Worst AQI Each Year
WITH ranked_aqi AS (
    SELECT 
        YEAR(date) AS year,
        CONCAT(state_name, ' - ', county_name) AS location,
        AVG(aqi) AS avg_aqi,
        RANK() OVER (
            PARTITION BY YEAR(date) 
            ORDER BY AVG(aqi) DESC
        ) AS `rank`
    FROM aqi_data
    GROUP BY year, state_name, county_name
)
SELECT 
    CONCAT(year, ' - ', location) AS year_location,
    avg_aqi
FROM ranked_aqi
WHERE `rank` <= 10
ORDER BY year, `rank`;

-- Top 10 Locationjs with Best Improvement
WITH aqi_1999 AS (
    SELECT 
        state_name, 
        county_name, 
        AVG(aqi) AS avg_1999
    FROM aqi_data
    WHERE YEAR(date) = 1999
    GROUP BY state_name, county_name
),
aqi_2023 AS (
    SELECT 
        state_name, 
        county_name, 
        AVG(aqi) AS avg_2023
    FROM aqi_data
    WHERE YEAR(date) = 2023
    GROUP BY state_name, county_name
)
SELECT 
    a1999.state_name,
    a1999.county_name,
    a1999.avg_1999,
    a2023.avg_2023,
    (a1999.avg_1999 - a2023.avg_2023) AS aqi_improvement
FROM aqi_1999 a1999
JOIN aqi_2023 a2023 
    ON a1999.state_name = a2023.state_name 
    AND a1999.county_name = a2023.county_name
ORDER BY aqi_improvement DESC
LIMIT 10;

-- Unhealthy Days in Utah Counties
SELECT 
    CONCAT(year, ' - ', county_name) AS year_county,
    unhealthy_days
FROM (
    SELECT 
        YEAR(`date`) AS year,
        county_name,
        COUNT(*) AS unhealthy_days
    FROM aqi_data
    WHERE 
        state_name = 'Utah'
        AND category = 'Unhealthy'
        AND county_name IS NOT NULL
    GROUP BY year, county_name 
) AS aggregated_data
ORDER BY year, county_name;

-- Salt Lake County Unhealthy Days by Months 
SELECT 
    YEAR(date) AS year,
    MONTH(date) AS month,
    COUNT(*) AS unhealthy_days
FROM aqi_data
WHERE 
    state_name = 'Utah'
    AND county_name = 'Salt Lake'
    AND category = 'Unhealthy'
GROUP BY year, month
ORDER BY year, month;



-- Salt Lake County Unhealthy Days by Year and Month
SELECT 
    CONCAT(YEAR(date), ' - ', LPAD(MONTH(date), 2, '0')) AS year_mth,
    COUNT(*) AS unhealthy_days
FROM aqi_data
WHERE 
    state_name = 'Utah'
    AND county_name = 'Salt Lake'
    AND category = 'Unhealthy'
GROUP BY year_mth
ORDER BY year_mth;



