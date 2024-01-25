-- Employee Demographics Table Creation --
CREATE TABLE EmployeeDemographics (
    EmployeeID INT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Age INT,
    Gender VARCHAR(50)
);

-- Employee Salary Table Creation --
CREATE TABLE EmployeeSalary (
    EmployeeID INT,
    JobTitle VARCHAR(50),
    Salary INT
);

--  Inserting Data into Employee Demographics --
INSERT INTO EmployeeDemographics VALUES
    (1001, 'Jim', 'Halpert', 30, 'Male'),
    (1002, 'Pam', 'Beasley', 30, 'Female'),
    (1003, 'Dwight', 'Schrute', 29, 'Male'),
    (1004, 'Angela', 'Martin', 31, 'Female'),
    (1005, 'Toby', 'Flenderson', 32, 'Male'),
    (1006, 'Michael', 'Scott', 35, 'Male'),
    (1007, 'Meredith', 'Palmer', 32, 'Female'),
    (1008, 'Stanley', 'Hudson', 38, 'Male'),
    (1009, 'Kevin', 'Malone', 31, 'Male');

-- Inserting Data into Employee Salary --
INSERT INTO EmployeeSalary VALUES
    (1001, 'Salesman', 45000),
    (1002, 'Receptionist', 36000),
    (1003, 'Salesman', 63000),
    (1004, 'Accountant', 47000),
    (1005, 'HR', 50000),
    (1006, 'Regional Manager', 65000),
    (1007, 'Supplier Relations', 41000),
    (1008, 'Salesman', 48000),
    (1009, 'Accountant', 42000);

-- SELECT AND FROM STATEMENTS --
-- Selecting all columns from EmployeeDemographics --
SELECT * FROM EmployeeDemographics;

-- Selecting specific columns --
SELECT FirstName, LastName, Age FROM EmployeeDemographics;

-- WHERE CLAUSE -- 
-- Select employees older than 30 --
SELECT * FROM EmployeeDemographics WHERE Age > 30;

-- UPDATING DATA --
-- Update job title --
UPDATE EmployeeSalary SET JobTitle = 'Senior Salesman' WHERE EmployeeID = 1001;

-- DELETING DATA --
-- Delete an employee record --
DELETE FROM EmployeeDemographics WHERE EmployeeID = 1009;

-- ALIASING --
-- Aliasing table and columns --
SELECT d.FirstName AS First, d.LastName AS Last, s.Salary FROM EmployeeDemographics d JOIN EmployeeSalary s ON d.EmployeeID = s.EmployeeID;

-- PARTITION BY --
-- Use of Partition By --
-- Use of Partition By with explicit JOIN condition
SELECT 
    d.FirstName, 
    d.LastName, 
    s.Salary, 
    RANK() OVER (PARTITION BY s.JobTitle ORDER BY s.Salary DESC) AS RankInJob
FROM 
    EmployeeDemographics d 
JOIN 
    EmployeeSalary s 
ON 
    d.EmployeeID = s.EmployeeID;

-- COMMON TABLE EXPRESSION --
-- Common Table Expression (CTE) with explicit JOIN condition --
WITH RankedEmployees AS (
    SELECT 
        d.FirstName, 
        d.LastName, 
        s.Salary, 
        s.JobTitle,
        RANK() OVER (ORDER BY s.Salary DESC) AS SalaryRank
    FROM 
        EmployeeDemographics d 
    JOIN 
        EmployeeSalary s 
    ON 
        d.EmployeeID = s.EmployeeID
)
SELECT * FROM RankedEmployees WHERE SalaryRank <= 5;

-- TEMP TABLE --
-- Creating a temporary table in SQL Server --
CREATE TABLE #TempEmployees (
    EmployeeID INT,
    FirstName VARCHAR(50),
    LastName VARCHAR(50),
    Age INT,
    Gender VARCHAR(50)
);

INSERT INTO #TempEmployees
SELECT * FROM EmployeeDemographics WHERE Age > 30;

-- Select from the temporary table --
SELECT * FROM #TempEmployees;

-- Drop the temporary table when done --
DROP TABLE #TempEmployees;

-- STRING FUNCTIONS --
-- String function example: CONCAT --
SELECT CONCAT(FirstName, ' ', LastName) AS FullName FROM EmployeeDemographics;

-- String function example: UPPER --
SELECT UPPER(FirstName) AS FirstName FROM EmployeeDemographics;

-- STORED PROCEDURES AND USE CASES --
-- Creating a stored procedure --
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'GetEmployeeDetails')
    DROP PROCEDURE GetEmployeeDetails;
GO

CREATE PROCEDURE GetEmployeeDetails @EmployeeID INT
AS
BEGIN
    SELECT * FROM EmployeeDemographics WHERE EmployeeID = @EmployeeID;
    SELECT * FROM EmployeeSalary WHERE EmployeeID = @EmployeeID;
END;
GO

EXEC GetEmployeeDetails @EmployeeID = 1001;  -- Replace 1001 with the desired EmployeeID

-- SUBQUERIES --
-- Example of a subquery --
SELECT * FROM EmployeeDemographics WHERE Age > (SELECT AVG(Age) FROM EmployeeDemographics);

-- REAL LIFE EXAMPLES --

-- Add back Emp 1009 --
INSERT INTO EmployeeDemographics (EmployeeID, FirstName, LastName, Age, Gender)
VALUES (1009, 'Kevin', 'Malone', 31, 'Male');
-- Recieve basic information about employees --
SELECT * FROM EmployeeDemographics;
SELECT * FROM EmployeeSalary;

-- Join the tables for a comprehensive view --
SELECT 
    d.EmployeeID, d.FirstName, d.LastName, d.Age, d.Gender, 
    s.JobTitle, s.Salary
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID;

-- Aggregated data analysis --
-- Analyze salary data to find avg salary by job title --
SELECT 
    JobTitle, 
    AVG(Salary) AS AverageSalary
FROM 
    EmployeeSalary
GROUP BY 
    JobTitle;

-- Determine employees in a specific age range or jobe title --
-- Employees between ages 30 and 40m --
SELECT * FROM EmployeeDemographics WHERE Age BETWEEN 30 AND 40;

-- Specific job title -- 
SELECT * FROM EmployeeSalary WHERE JobTitle = 'Salesman';

-- Trends and Patterns --
-- Identify salary trends across different age groups --
SELECT 
    d.Age, 
    AVG(s.Salary) AS AverageSalary
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID
GROUP BY 
    d.Age
ORDER BY 
    d.Age;

-- Ranking and Window Functions --
-- Rank employees within their job titles based on salary --
SELECT 
    FirstName, LastName, JobTitle, Salary,
    RANK() OVER (PARTITION BY JobTitle ORDER BY Salary DESC) AS SalaryRank
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID;

-- Data Manipulation for Reporting --
-- Prepare data for monthly or annual reports --
-- Total Salary Expenditure --
SELECT 
    SUM(Salary) AS TotalSalaryExpenditure
FROM 
    EmployeeSalary;
-- Avergae Salary by Job Title --
SELECT 
    JobTitle, 
    AVG(Salary) AS AverageSalary
FROM 
    EmployeeSalary
GROUP BY 
    JobTitle;
-- Employee Age Distribution --
SELECT 
    Age, 
    COUNT(*) AS NumberOfEmployees
FROM 
    EmployeeDemographics
GROUP BY 
    Age
ORDER BY 
    Age;
-- Highest and Lowest Paid Employees --
-- Highest paid
SELECT TOP 1 
    d.FirstName, d.LastName, s.Salary 
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID
ORDER BY 
    s.Salary DESC;

-- Lowest paid
SELECT TOP 1 
    d.FirstName, d.LastName, s.Salary 
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID
ORDER BY 
    s.Salary;

-- Gender Salary Equity --
SELECT 
    d.Gender, 
    AVG(s.Salary) AS AverageSalary
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID
GROUP BY 
    d.Gender;

-- Ad-Hoc Queries for Quick Insights --
-- Finding the highest paid employee --
SELECT TOP 1 
    FirstName, LastName, Salary 
FROM 
    EmployeeDemographics d
JOIN 
    EmployeeSalary s ON d.EmployeeID = s.EmployeeID
ORDER BY 
    Salary DESC;

-- Data Quality Test --
-- Check for null or missing values
SELECT * FROM EmployeeDemographics WHERE FirstName IS NULL OR LastName IS NULL;

-- Duplicate records check
SELECT EmployeeID, COUNT(*) FROM EmployeeDemographics GROUP BY EmployeeID HAVING COUNT(*) > 1;








