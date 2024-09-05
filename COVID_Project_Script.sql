 SELECT * FROM PortfolioProject..CovidDeaths
Where continent is not null
 Order by 3,4


  -- SELECT * FROM PortfolioProject..CovidVaccinations


  -- SELECT Data 

  SELECT Location, date, total_cases, new_cases, total_deaths, population
  FROM PortfolioProject..CovidDeaths
  Where continent is not null
  order by 1,2

-- Calculation - looking at total cases vs total deaths
-- Shows likelihood of dying if you contract the covid in your country
  SELECT Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage
  FROM PortfolioProject..CovidDeaths
  WHERE location like '%states%'
  and continent is not null
  order by 1,2


  -- Total cases vs populations
  SELECT Location, date, total_cases, population, (total_cases/population)*100 as populationaffectedcovid_Percentage
  FROM PortfolioProject..CovidDeaths
  WHERE location like '%states%'
  and continent is not null
  order by 1,2


  -- Country with highest infection
  SELECT Location,MAX(total_cases) as HighestInfectionCount, population, Max((total_cases/population))*100 as populationaffectedcovid_Percentage
  FROM PortfolioProject..CovidDeaths
  Where continent is not null
  -- WHERE location like '%states%'
  Group By location, population
  order by populationaffectedcovid_Percentage desc


  -- Total number of people deasth by country
  SELECT Location, MAX(cast(total_deaths as int)) as HighestdeathCount
  FROM PortfolioProject..CovidDeaths
  Where continent is not null
  -- WHERE location like '%states%'
  Group By location
  Order by HighestdeathCount desc


  -- Break down By Continent

  SELECT continent, MAX(cast(total_deaths as int)) as TotaldeathCount
  FROM PortfolioProject..CovidDeaths
  Where continent is not null
  -- WHERE location like '%states%'
  Group By continent
  Order by TotaldeathCount desc


-- Showing continent with highest count per population

  SELECT continent, MAX(cast(total_deaths as int)) as TotaldeathCount
  FROM PortfolioProject..CovidDeaths
  Where continent is not null
  Group By continent
  Order by TotaldeathCount desc


-- Global NUMBERS
  SELECT  SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(new_cases)*100 as DeathPercentage
  FROM PortfolioProject..CovidDeaths
 -- WHERE location like '%states%'
  where continent is not null
  -- Group By date
  order by 1,2


-- Looking at Total Population vs Vaccination ( merging to Database)


SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as INT)) over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
order by 2,3


-- USE CTE

With PopVsVacci (Continent, Location, Date, Population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as INT)) over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
-- Order by 2,3
)
SELECT * , (RollingPeopleVaccinated / Population)* 100
FROM PopVsVacci



-- TEMP TABLE
/*
DROP Table if exists #PercentPopulationVacinated
Create Table #PercentPopulationVacinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population varchar,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)


Insert into #PercentPopulationVacinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CAST(vac.new_vaccinations as INT)) over (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100

FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--Where dea.continent is not null
-- Order by 2,3

SELECT * , (RollingPeopleVaccinated / Population)* 100
FROM #PercentPopulationVacinated */

-- Drop the temporary table if it exists
DROP TABLE IF EXISTS #PercentPopulationVaccinated;

-- Create the temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_vaccinations NUMERIC,
    RollingPeopleVaccinated NUMERIC
);

-- Insert data into the temporary table
INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CAST(dea.population AS NUMERIC) AS population, 
    TRY_CAST(vac.new_vaccinations AS NUMERIC) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRY_CAST(dea.population AS NUMERIC) IS NOT NULL
    AND TRY_CAST(vac.new_vaccinations AS NUMERIC) IS NOT NULL;

-- Select data from the temporary table with the calculated percentage
SELECT 
    *, 
    (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM 
    #PercentPopulationVaccinated;

-- Creating view to save data for later visualization

Create View PercentPopulationVaccinated as

SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    TRY_CAST(dea.population AS NUMERIC) AS population, 
    TRY_CAST(vac.new_vaccinations AS NUMERIC) AS new_vaccinations,
    SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    TRY_CAST(dea.population AS NUMERIC) IS NOT NULL
    AND TRY_CAST(vac.new_vaccinations AS NUMERIC) IS NOT NULL;

SELECT * 
FROM PercentPopulationVaccinated