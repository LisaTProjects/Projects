-- Simple Data Cleaning --
-- Convert 'reservation_status_date' to date format --
ALTER TABLE LisaPortfolioProject.dbo.HotelBookings
ALTER COLUMN reservation_status_date DATE;

-- Normalize string values --
UPDATE LisaPortfolioProject.dbo.HotelBookings
SET hotel = UPPER(hotel),
    arrival_date_month = UPPER(arrival_date_month),
    meal = UPPER(meal);

-- Add a new column to store the combined date --
ALTER TABLE LisaPortfolioProject.dbo.HotelBookings
ADD arrival_date DATE;

-- Update the new column with the combined date --
-- This script assumes the format of 'arrival_date_month' is full month name (e.g., 'January', 'February', etc.)
ALTER TABLE LisaPortfolioProject.dbo.HotelBookings
ADD arrival_date DATE;

UPDATE LisaPortfolioProject.dbo.HotelBookings
SET arrival_date = CAST(
    arrival_date_year 
    + '-' + 
    RIGHT('0' + CAST(MONTH(CAST(arrival_date_month + ' 1 2000' AS DATE)) AS VARCHAR(2)), 2) 
    + '-' + 
    RIGHT('0' + CAST(arrival_date_day_of_month AS VARCHAR(2)), 2)
    AS DATE);

-- Select sample rows to verify the 'arrival_date' column --
SELECT TOP 10 arrival_date_year, arrival_date_month, arrival_date_day_of_month, arrival_date
FROM LisaPortfolioProject.dbo.HotelBookings;

ALTER TABLE LisaPortfolioProject.dbo.HotelBookings
DROP COLUMN arrival_date_year, arrival_date_month, arrival_date_day_of_month;

-- Test --
SELECT *
FROM LisaPortfolioProject.dbo.HotelBookings

-- Average Stay Duration (Weekdays and Weekends) --
SELECT 
    AVG(stays_in_week_nights) AS avg_week_nights, 
    AVG(stays_in_weekend_nights) AS avg_weekend_nights
FROM LisaPortfolioProject.dbo.HotelBookings;

-- Cancellation Rate (CR) --
-- 37% --
SELECT 
    (SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT)) * 100 AS cancellation_rate
FROM LisaPortfolioProject.dbo.HotelBookings;

-- CR per quarter --
-- Highest quarter found was in Q2 in 2027 at 43% --
-- Highest overall quarter is Q3 --
SELECT 
    YEAR(arrival_date) AS year,
    DATEPART(QUARTER, arrival_date) AS quarter,
    (SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT)) * 100 AS cancellation_rate
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY 
    YEAR(arrival_date),
    DATEPART(QUARTER, arrival_date)
ORDER BY 
    YEAR(arrival_date),
    DATEPART(QUARTER,arrival_date);

-- Determine CR for each groups (family, couple, other) --
-- Couples at 39.7%, Families at 35%, and Other 30% --
SELECT 
    booking_type,
    total_bookings,
    total_cancellations,
    (total_cancellations / CAST(total_bookings AS FLOAT)) * 100 AS cancellation_percentage
FROM (
    SELECT 
        CASE 
            WHEN TRY_CONVERT(INT, adults) = 2 AND TRY_CONVERT(INT, children) = 0 AND TRY_CONVERT(INT, babies) = 0 THEN 'Couples'
            WHEN TRY_CONVERT(INT, children) > 0 OR TRY_CONVERT(INT, babies) > 0 THEN 'Family'
            ELSE 'Other'
        END AS booking_type,
        COUNT(*) AS total_bookings,
        SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS total_cancellations
    FROM LisaPortfolioProject.dbo.HotelBookings
    WHERE 
        TRY_CONVERT(INT, adults) IS NOT NULL AND 
        TRY_CONVERT(INT, children) IS NOT NULL AND 
        TRY_CONVERT(INT, babies) IS NOT NULL
    GROUP BY 
        CASE 
            WHEN TRY_CONVERT(INT, adults) = 2 AND TRY_CONVERT(INT, children) = 0 AND TRY_CONVERT(INT, babies) = 0 THEN 'Couples'
            WHEN TRY_CONVERT(INT, children) > 0 OR TRY_CONVERT(INT, babies) > 0 THEN 'Family'
            ELSE 'Other'
        END
) AS subquery
ORDER BY booking_type;

-- Most Common Countries of Origin for Guests --
-- Most common is PRT --
SELECT country, COUNT(*) AS number_of_guests
FROM LisaPortfolioProject.dbo.HotelBookings
WHERE is_canceled = 0
GROUP BY country
ORDER BY number_of_guests DESC;

-- Average Daily Rate (ADR) by Room Type --
-- $91 to $125 --
SELECT reserved_room_type, AVG(adr) AS average_adr
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY reserved_room_type;

-- Highest Average Daily Rate (ADR) per country-- 
-- Highest ADR is PRT --
SELECT country, MAX(adr) AS highest_adr
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY country
ORDER BY highest_adr DESC;

-- Number of Special Requests by Reservation Status ---
SELECT reservation_status, SUM(total_of_special_requests) AS total_special_requests
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY reservation_status;

-- Average Lead Time for Cancellations vs. Non-Cancellations --
SELECT 
    is_canceled, 
    AVG(lead_time) AS average_lead_time
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY is_canceled;

-- Cancellation rate for bookings made by each agent--
-- Agent 220 has the lowest canvcellation rate --
SELECT 
    agent,
    COUNT(*) AS total_bookings,
    SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) AS total_cancellations,
    (SUM(CASE WHEN is_canceled = 1 THEN 1 ELSE 0 END) / CAST(COUNT(*) AS FLOAT)) * 100 AS cancellation_rate
FROM LisaPortfolioProject.dbo.HotelBookings
WHERE agent IS NOT NULL
GROUP BY agent
ORDER BY cancellation_rate DESC;

-- Calculate the average sales (presumably represented by the Average Daily Rate, ADR) per agent --
-- Highest avg. sales based on ADR is agent 404, 426, 70, 433 508 --
SELECT 
    agent,
    AVG(adr) AS average_sales
FROM LisaPortfolioProject.dbo.HotelBookings
WHERE agent IS NOT NULL
GROUP BY agent
ORDER BY average_sales DESC;

-- Find top 10 sales agents --
SELECT TOP 10 agent
FROM LisaPortfolioProject.dbo.HotelBookings
WHERE agent IS NOT NULL
GROUP BY agent
ORDER BY AVG(adr) DESC;

-- Find the Countries for These Top Agents --
-- Top Countries are PRT and FRA --
SELECT 
    b.agent,
    b.country,
    COUNT(*) AS number_of_bookings
FROM 
    LisaPortfolioProject.dbo.HotelBookings b
INNER JOIN (
    SELECT TOP 10 agent
    FROM LisaPortfolioProject.dbo.HotelBookings
    WHERE agent IS NOT NULL
    GROUP BY agent
    ORDER BY AVG(adr) DESC
) AS top_agents ON b.agent = top_agents.agent
WHERE b.country IS NOT NULL
GROUP BY b.agent, b.country
ORDER BY b.agent, number_of_bookings DESC;

-- Which group (Families, Couples, or Others) spends the most money --
-- Couples spend total revenue of $17462433.87 --
-- Families $3351288.65
-- Other $5182537.89
SELECT 
    booking_type,
    SUM(total_revenue) AS total_revenue
FROM (
    SELECT 
        CASE 
            WHEN TRY_CONVERT(INT, adults) = 2 AND TRY_CONVERT(INT, children) = 0 AND TRY_CONVERT(INT, babies) = 0 THEN 'Couples'
            WHEN TRY_CONVERT(INT, children) > 0 OR TRY_CONVERT(INT, babies) > 0 THEN 'Family'
            ELSE 'Other'
        END AS booking_type,
        (adr * (stays_in_week_nights + stays_in_weekend_nights)) AS total_revenue
    FROM LisaPortfolioProject.dbo.HotelBookings
    WHERE 
        is_canceled = 0 AND
        TRY_CONVERT(INT, adults) IS NOT NULL AND 
        TRY_CONVERT(INT, children) IS NOT NULL AND 
        TRY_CONVERT(INT, babies) IS NOT NULL
) AS subquery
GROUP BY booking_type
ORDER BY total_revenue DESC;

-- Percentage of bookings based on distribution channel --
-- 82% of booking is used by TA/TO
-- 12% ok booking is used by Direct
SELECT 
    distribution_channel,
    COUNT(*) AS total_bookings,
    (COUNT(*) / CAST((SELECT COUNT(*) FROM LisaPortfolioProject.dbo.HotelBookings) AS FLOAT)) * 100 AS percentage_of_bookings
FROM LisaPortfolioProject.dbo.HotelBookings
GROUP BY distribution_channel
ORDER BY percentage_of_bookings DESC;