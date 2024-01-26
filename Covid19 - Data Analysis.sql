-- Select Data --
Select Location, date, total_cases, new_cases, total_deaths, population
From LisaPortfolioProject..CovidDeaths
Where continent is not null 
order by 1,2

-- Total Cases vs Total Deaths --
-- This shows likelihood of dying if contract Covid-19 in Canada --
-- The highest amount of deaths was on June 21, 2020 with a the highest death percentage of 8.3% --
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From LisaPortfolioProject..CovidDeaths
Where location like '%Canada%'
and continent is not null 
order by 1,2

-- Total Cases vs Population --
-- This shows what percentage of population infected with Covid --
Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From LisaPortfolioProject..CovidDeaths
--Where location like '%Canada%'
order by 1,2

-- Showing nations with the highest infection rate relative to their population --
Select Location, Population, MAX(total_cases) as HighestInfectionCount,  Max((total_cases/population))*100 as PercentPopulationInfected
From LisaPortfolioProject..CovidDeaths
--Where location like '%Canada%'
Group by Location, Population
order by PercentPopulationInfected desc

-- Nations with the highest death count in relation to their population --
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From LisaPortfolioProject..CovidDeaths
--Where location like '%Canada%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- Canada COVID-19 Weekly Trends --
-- Shows the weekly changes in cases and deaths in Canada --
SELECT 
    Location, 
    DATEPART(week, date) AS WeekNumber, 
    YEAR(date) AS Year,
    SUM(new_cases) AS WeeklyNewCases, 
    SUM(new_deaths) AS WeeklyNewDeaths
FROM 
    LisaPortfolioProject..CovidDeaths
WHERE 
    location = 'Canada'
GROUP BY 
    Location, DATEPART(week, date), YEAR(date)
ORDER BY 
    Year, WeekNumber;

-- Canada Vaccination Coverage Over Time --
-- Shows the cumulative percentage of the population vaccinated over time --
WITH CanadaVaccinationData AS (
    SELECT
        date,
        SUM(CAST(NULLIF(new_vaccinations, '') AS bigint)) OVER (ORDER BY date) AS CumulativeVaccinations
    FROM
        LisaPortfolioProject..CovidVaccinations
    WHERE
        location = 'Canada'
        AND ISNUMERIC(new_vaccinations) = 1
)
SELECT
    date,
    CumulativeVaccinations,
    (CAST(CumulativeVaccinations AS decimal(20, 4)) / (SELECT population FROM LisaPortfolioProject..CovidDeaths WHERE location = 'Canada' AND date = (SELECT MAX(date) FROM LisaPortfolioProject..CovidDeaths WHERE location = 'Canada'))) * 100 AS VaccinationCoveragePercentage
FROM
    CanadaVaccinationData
ORDER BY
    date;

-- Canada COVID-19 Mortality Rate Over Time --
-- Calculates the mortality rate over time in Canada --
SELECT 
    date,
    (CAST(SUM(new_deaths) AS decimal(20, 4)) / NULLIF(SUM(new_cases), 0)) * 100 AS MortalityRate
FROM 
    LisaPortfolioProject..CovidDeaths
WHERE 
    location = 'Canada'
GROUP BY 
    date
ORDER BY 
    date;

-- Analyzing by Continent --
-- Displaying continents with the highest death count relative to their population --
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From LisaPortfolioProject..CovidDeaths
--Where location like '%Canada%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- Global numbers --
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From LisaPortfolioProject..CovidDeaths
--Where location like '%Canada%'
where continent is not null 
--Group By date
order by 1,2

-- Population vs. Vaccination Coverage --
-- COVID-19 Vaccination Progress and Population Impact by Region --
WITH VaccinationData AS (
    SELECT
        dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(CONVERT(bigint, ISNULL(vac.new_vaccinations, 0))) OVER (PARTITION BY dea.location ORDER BY dea.date) as RollingPeopleVaccinated
    FROM
        LisaPortfolioProject..CovidDeaths dea
    JOIN
        LisaPortfolioProject..CovidVaccinations vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE
        dea.continent IS NOT NULL
)

SELECT
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPeopleVaccinated,
    (CAST(RollingPeopleVaccinated as decimal(20, 4)) / NULLIF(population, 0)) * 100 as VaccinationCoveragePercentage
FROM
    VaccinationData
ORDER BY
    location,
    date;

-- Creating View to store data for later visualizations --
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From LisaPortfolioProject..CovidDeaths dea
Join LisaPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

Select *
From PercentPopulationVaccinated
