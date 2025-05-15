USE amazon_delivery;

-- Data Cleaning 
SELECT *
FROM amazon_delivery2
WHERE Store_Latitude = 0 AND Store_Longitude = 0;

SELECT *
FROM amazon_delivery2
WHERE Drop_Latitude = 0 OR Drop_Longitude = 0;

SELECT *
FROM amazon_delivery2
WHERE Store_Latitude NOT BETWEEN -90 AND 90
 AND Store_Longitude NOT BETWEEN -180 AND 180
 AND Drop_Latitude NOT BETWEEN -90 AND 90
 AND Drop_Longitude NOT BETWEEN -180 AND 180;
 
-- Creating a new table With out null store latitudes and longitudes 

SELECT *
FROM amazon_delivery2;

CREATE TABLE clean_amazon_delivery2
SELECT *
FROM amazon_delivery2
WHERE Store_Latitude != 0 AND Store_Longitude != 0;

SELECT *
FROM clean_amazon_delivery2;

-- Uncover insights into factors influencing delivery efficiency 

-- 1. duration before pickup after order 

SELECT TIMEDIFF(Pickup_Time, Order_Time) AS Time_of_Pickup
FROM clean_amazon_delivery2; 

SELECT Order_ID, 
       TIME_TO_SEC(TIMEDIFF(Pickup_Time, Order_Time)) / 60 AS Time_of_Pickup_mins
FROM clean_amazon_delivery2;       

-- 2. deivery time and date after pickup 

SELECT CONCAT(Order_Date, ' ', Pickup_Time) AS pickup_datetime, DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL Delivery_Time HOUR) AS Delivery_Date_Time
FROM clean_amazon_delivery2; 

-- 3. distance from the store 

SELECT 6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
  )
) AS Distance_KM
FROM clean_amazon_delivery2
; 

-- delivery time and date after pick up 

SELECT Order_Date, Pickup_Time, DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL Delivery_Time HOUR) AS Delivery_Date_Time
FROM clean_amazon_delivery2; 

-- OR  

SELECT Order_ID,
       Order_Date,
       Order_Time,
	   DATE(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Date,
	   TIME(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Time 
FROM clean_amazon_delivery2;

-- Speed of delivery 

SELECT Order_ID, Distance_KM / Delivery_Time AS Avg_speed_kmph
FROM (
      SELECT *, 6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
      COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
      POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
      )
	) AS Distance_KM
     FROM clean_amazon_delivery2) AS subquery ;
     
--  Try to select every column apart from the store latitude / longitude and drop logitude / latitude     
     
SELECT *
FROM clean_amazon_delivery2;  --  first select all the data to be sure of what we need  
     
SELECT Order_ID, 
       Order_Time,
       Order_Date,
       Agent_Age, 
       Agent_Rating, 
       Weather, 
       Traffic, 
       Vehicle, 
       Area, 
       Category, 
       Delivery_Time,
       TIME_TO_SEC(TIMEDIFF(Pickup_Time, Order_Time)) / 60 AS Time_of_Pickup_mins,
       TIMEDIFF(Pickup_Time, Order_Time) AS Time_of_Pickup,
       DATE(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Date,
	   TIME(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Time,
       6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
       COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
       POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
       )
) AS Distance_KM, CONCAT(Order_Date, ' ', Pickup_Time) AS pickup_datetime, 
				  DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), 
                  INTERVAL Delivery_Time HOUR) AS Delivery_Date_Time
FROM clean_amazon_delivery2;

-- we are unable to combian the delivery speed in the above statement

SELECT Order_ID, Distance_KM / Delivery_Time AS Avg_speed_kmph
FROM (
      SELECT *, 6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
      COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
      POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
      )
	) AS Distance_KM
     FROM clean_amazon_delivery2) AS subquery ; 
     
     
-- Using CTE to include the speed of delivery 


WITH CTE_NUM_1 AS
(
SELECT Order_ID, 
       Order_Time,
       Order_Date,
       Agent_Age, 
       Agent_Rating, 
       Weather, 
       Traffic, 
       Vehicle, 
       Area, 
       Category, 
       Delivery_Time,
       TIME_TO_SEC(TIMEDIFF(Pickup_Time, Order_Time)) / 60 AS Time_of_Pickup_mins,
       TIMEDIFF(Pickup_Time, Order_Time) AS Time_of_Pickup,
       DATE(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Date,
	   TIME(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Time_1,
       ROUND(
       6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
       COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
       POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
       ))
) AS Distance_KM
FROM clean_amazon_delivery2

),
CTE_NUM_2 AS
(
SELECT Order_ID, Distance_KM / Delivery_Time AS Avg_speed_kmph
FROM (
      SELECT *, ROUND (6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
      COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
      POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
      ))
	) AS Distance_KM
     FROM clean_amazon_delivery2) AS subquery 
)
SELECT *
FROM CTE_NUM_1 c1
    JOIN CTE_NUM_2 c2
    ON c1.Order_ID = c2.Order_ID 
    ORDER BY Delivery_Time;


-- We need to know which order was slow and which one was in time 

WITH CTE_NUM_1 AS
(
SELECT Order_ID, 
       Order_Time,
       Order_Date,
       Agent_Age, 
       Agent_Rating, 
       Weather, 
       Traffic, 
       Vehicle, 
       Area, 
       Category, 
       Delivery_Time,
       TIME_TO_SEC(TIMEDIFF(Pickup_Time, Order_Time)) / 60 AS Time_of_Pickup_mins,
       TIMEDIFF(Pickup_Time, Order_Time) AS Time_of_Pickup,
       DATE(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Date,
	   TIME(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Time_1,
       ROUND(
       6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
       COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
       POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
       ))
) AS Distance_KM
FROM clean_amazon_delivery2

),
CTE_NUM_2 AS
(
SELECT Order_ID, Distance_KM / Delivery_Time AS Avg_speed_kmph
FROM (
      SELECT *, ROUND (6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
      COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
      POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
      ))
	) AS Distance_KM
     FROM clean_amazon_delivery2) AS subquery 
)
SELECT *, 
       CASE 
         WHEN (Distance_KM BETWEEN 0 AND 500) AND (Delivery_Time <= 35) THEN 'On Time'
		 WHEN (Distance_KM BETWEEN 501 AND 1000) AND (Delivery_Time <= 70) THEN 'On Time'
         WHEN (Distance_KM BETWEEN 1001 AND 1500) AND (Delivery_Time <= 105) THEN 'On Time'
         WHEN (Distance_KM BETWEEN 1501 AND 2000) AND (Delivery_Time <= 150) THEN 'On Time'
         ELSE 'Late' 
      END AS Delivery_Status
FROM CTE_NUM_1 c1
    JOIN CTE_NUM_2 c2
    ON c1.Order_ID = c2.Order_ID;
    
-- How Age Influences Delivery Efficeincy 
    
WITH CTE_NUM_1 AS
(
SELECT Order_ID, 
       Order_Time,
       Order_Date,
       Agent_Age, 
       Agent_Rating, 
       Weather, 
       Traffic, 
       Vehicle, 
       Area, 
       Category, 
       Delivery_Time,
       TIME_TO_SEC(TIMEDIFF(Pickup_Time, Order_Time)) / 60 AS Time_of_Pickup_mins,
       TIMEDIFF(Pickup_Time, Order_Time) AS Time_of_Pickup,
       DATE(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Date,
	   TIME(DATE_ADD(CONCAT(Order_Date, ' ', Pickup_Time), INTERVAL delivery_time HOUR)) AS Delivery_Time_1,
       ROUND(
       6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
       COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
       POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
       ))
) AS Distance_KM
FROM clean_amazon_delivery2

),
CTE_NUM_2 AS
(
SELECT Order_ID, Distance_KM / Delivery_Time AS Avg_speed_kmph
FROM (
      SELECT *, ROUND (6371*2*ASIN(SQRT(POWER(SIN(RADIANS(drop_latitude - store_latitude)/2), 2) + 
      COS(RADIANS(store_latitude)) * COS(RADIANS(drop_latitude)) * 
      POWER(SIN(RADIANS(drop_longitude - store_longitude) / 2), 2)
      ))
	) AS Distance_KM
     FROM clean_amazon_delivery2) AS subquery 
)
SELECT *, 
       CASE 
         WHEN (Distance_KM BETWEEN 0 AND 500) AND (Delivery_Time <= 35) THEN 'On Time'
		 WHEN (Distance_KM BETWEEN 501 AND 1000) AND (Delivery_Time <= 70) THEN 'On Time'
         WHEN (Distance_KM BETWEEN 1001 AND 1500) AND (Delivery_Time <= 105) THEN 'On Time'
         WHEN (Distance_KM BETWEEN 1501 AND 2000) AND (Delivery_Time <= 150) THEN 'On Time'
         ELSE 'Late' 
      END AS Delivery_Status
FROM CTE_NUM_1 c1
    JOIN CTE_NUM_2 c2
    ON c1.Order_ID = c2.Order_ID
    ORDER BY Avg_speed_kmph ;    
    
    -- 

    
    

