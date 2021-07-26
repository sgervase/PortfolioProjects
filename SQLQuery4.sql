/*
Exploratory Data Analysis with current COVID 19 data 
Skills used: Windows Functions, Aggregate Functions, Converting Data Types, Joins, CTEs, Temp Tables, Creating Views
*/

SELECT *
FROM Deaths
ORDER BY 3,4;

-- First, I select the data that I will be using

SELECT Location, date, population, total_cases, new_cases, total_deaths
FROM Deaths
ORDER BY 1,2;

-- Comparing total cases to total deaths
-- Because I am from the United States, I decided to focus more of my exploration on the U.S., but any country (or countries) can be used
-- Shows likelihood of death after contracting COVID

SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercent
FROM Deaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Total cases compared to Population
-- Shows percentage of population that has contracted COVID

SELECT Location, date, population, total_cases,(total_cases/population)*100 AS InfectionPercent
FROM Deaths
WHERE location LIKE '%states%'
ORDER BY 1,2

-- Look at different countries' infection rates compared to populations

SELECT Location, population, MAX(total_cases) AS PeakInfection, MAX((total_cases/population))*100 AS InfectionPercent
FROM Deaths
--WHERE location LIKE '%states%'
GROUP BY Location, Population
ORDER BY InfectionPercent DESC

-- Now, the death counts are explored among countries

SELECT Location, MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM Deaths
--WHERE location LIKE '%states%'
WHERE continent is not null
GROUP BY Location
ORDER BY HighestDeathCount DESC

--We can look at these counts from a broader perspective and split the data up by continent

SELECT location, MAX(CAST(total_deaths as int)) AS HighestDeathCount
FROM Deaths
--WHERE location LIKE '%states%'
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathCount DESC

--Going even further, we can look at the data at a global level day by day

SELECT date, SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercent
FROM Deaths
--WHERE location LIKE '%states%'
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

--To get the aggregate world numbers, we just remove the date related parts of the query, specifically the date column and the GROUP BY clause

SELECT SUM(new_cases) AS TotalCases, SUM(cast(new_deaths as int)) AS TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercent
FROM Deaths
--WHERE location LIKE '%states%'
WHERE continent is not null
--GROUP BY date
ORDER BY 1,2



--Now we can start to look at the vaccination data
--Look at total population vs vaccinations
--New vaccinations per day

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
FROM Deaths d
JOIN Vaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

--We can add a rolling count to find day by day total new vaccinations

SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.location ORDER BY d.location, d.date) AS RollingTotalVaccinated
FROM Deaths d
JOIN Vaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
ORDER BY 2,3

--Want to use our Rolling Total column to find rate at which people are vaccinated, but cannot use our column that we just created
--Solution #1: Use CTE

WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingTotalVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.location ORDER BY d.location, d.date) AS RollingTotalVaccinated
FROM Deaths d
JOIN Vaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3
)
SELECT *, (RollingTotalVaccinated/Population)*100 AS VaccinationRate
FROM PopvsVac
ORDER BY 2,3

--Solution #2: Temp Table
-- I added the DROP TABLE query in case I want to go back and change any part of our temp table

DROP TABLE if exists #VaccinationPercentage
CREATE TABLE #VaccinationPercentage
(
Continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
New_vaccinations numeric,
RollingTotalVaccinated numeric
)

INSERT INTO #VaccinationPercentage
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.location ORDER BY d.location, d.date) AS RollingTotalVaccinated
FROM Deaths d
JOIN Vaccinations v
	ON d.location = v.location
	and d.date = v.date
--WHERE d.continent is not null
--ORDER BY 2,3

SELECT *, (RollingTotalVaccinated/Population)*100 AS VaccinationRate
FROM #VaccinationPercentage
ORDER BY 2,3

--Creating View to store data for visualizations

CREATE VIEW VaccinationPercentage AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, 
SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.location ORDER BY d.location, d.date) AS RollingTotalVaccinated
FROM Deaths d
JOIN Vaccinations v
	ON d.location = v.location
	and d.date = v.date
WHERE d.continent is not null
--ORDER BY 2,3

SELECT *
FROM VaccinationPercentage