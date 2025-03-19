```sql
-- Covid 19 Data Exploration 

SELECT *
FROM Covid;

-- Select Data that we are going to be starting with

SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Covid
ORDER BY 1,2;

-- Total Cases vs Total Deaths
-- Represents chance of dying if you get infected with Covid in a certain country

SELECT 
    Location, 
    date, 
    total_cases, 
    total_deaths, 
    (CAST(total_deaths AS FLOAT) / NULLIF(CAST(total_cases AS FLOAT), 0)) * 100 AS DeathPercentage
FROM Covid
WHERE location = 'Australia'
ORDER BY 1, 2;

-- Total Cases vs Population
-- The percentage of the population infected with Covid

SELECT Location, date, Population, total_cases,  
       (CAST(total_cases AS FLOAT) / NULLIF(CAST(population AS FLOAT), 0)) * 100 AS PercentPopulationInfected
FROM Covid
ORDER BY 1,2;

-- Countries with Highest Infection Rate compared to Population

SELECT 
    Location, 
    population,
    MAX(CAST(total_cases AS FLOAT)) AS Highest_Infection_Number,  
    MAX(CAST(total_cases AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100 AS Percent_Population_Infected
FROM Covid
GROUP BY Location, population
ORDER BY Percent_Population_Infected DESC;

-- Countries with Highest Death Count per Population

SELECT Location, 
       MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount,
       MAX(CAST(total_deaths AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100 AS Percent_Population_deaths
FROM Covid
GROUP BY Location
ORDER BY Percent_Population_deaths DESC;

-- BREAKING THINGS DOWN BY CONTINENT

-- Continents with the highest death count per population

SELECT continent, 
       MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount, 
       MAX(CAST(total_deaths AS FLOAT) / NULLIF(CAST(Population AS FLOAT), 0)) * 100 AS Percent_Population_deaths
FROM Covid
WHERE continent <> ' '
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- GLOBAL NUMBERS

SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS INT)) AS total_deaths, 
       SUM(CAST(new_deaths AS INT)) / SUM(New_Cases) * 100 AS DeathPercentage
FROM Covid
WHERE continent <> ' '
ORDER BY 1,2;

-- Total Population vs Vaccinations

SELECT continent, location, date, population, new_vaccinations,
       SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY Location ORDER BY Date) AS RollingPeopleVaccinated
FROM Covid
WHERE continent <> ' ' 
ORDER BY 2,3;

-- Using CTE to perform Calculation on Partition By in previous query

WITH Pop_Vac AS (
    SELECT 
        continent, 
        location, 
        date, 
        population, 
        new_vaccinations,
        SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY Location ORDER BY Date) AS Rolling_People_Vaccinated
    FROM Covid
    WHERE continent <> ' ' 
)
SELECT *, 
       (Rolling_People_Vaccinated / NULLIF(CAST(Population AS FLOAT), 0)) * 100 AS per_vac
FROM Pop_Vac
ORDER BY location, date;

-- Creating View to store data for later visualizations

CREATE VIEW Percent_Population_Vaccinated AS
SELECT continent, location, date, population, new_vaccinations,
       SUM(CONVERT(INT, new_vaccinations)) OVER (PARTITION BY Location ORDER BY Date) AS Rolling_People_Vaccinated
FROM Covid
WHERE continent <> ' '; 
