SELECT *
FROM PortfolioProject_Covid..CovidDeaths
ORDER BY 3,4

----SELECT *
----FROM PortfolioProject_Covid..CovidVaccinations
----ORDER BY 3,4

-- Select Data

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject_Covid..CovidDeaths
ORDER BY 1,2


-- Looking at Total Cases vs. Total Deaths per Location

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject_Covid..CovidDeaths
WHERE location like '%states%'
ORDER BY 1,2

-- Looking at Total Cases vs. Population
SELECT location, date, population, total_cases, (total_cases/population)*100 AS CasePercentage
FROM PortfolioProject_Covid..CovidDeaths
-- WHERE location like '%states%'
ORDER BY 1,2


-- Which countries have the highest infection rates?
SELECT location, population, MAX(total_cases) AS MaxInfectionCount, MAX((total_cases/population))*100 AS CasePercentage
FROM PortfolioProject_Covid..CovidDeaths
GROUP BY location, population
ORDER BY CasePercentage desc

-- Which countries have the highest death rates?
SELECT location, population, MAX(total_deaths) AS MaxDeathCount, MAX((total_deaths/total_cases))*100 AS DeathPercentage
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT null
GROUP BY location, population
ORDER BY population desc

-- Showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths AS int)) AS TotalDeathCount 
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT null
GROUP BY location
ORDER BY TotalDeathCount desc

-- view by continent (Alex said this is the right way, but kept the other way for visual drill downs)
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject_Covid..CovidDeaths
WHERE (continent IS null AND location NOT LIKE '%income%')
GROUP BY location
ORDER BY TotalDeathCount desc

-- showing continents with highest death counts
SELECT continent, MAX(cast(total_deaths AS int)) as TotalDeathCount
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT null
GROUP BY continent
ORDER BY TotalDeathCount desc

-- global numbers
SELECT  date, SUM(new_cases) AS total_cases, SUM(cast (new_deaths as int)) AS total_Deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
FROM PortfolioProject_Covid..CovidDeaths
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1,2

-- joining tables 
SELECT *
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date

-- Looking at total population vs vaccines
SELECT dea.location, MAX(population) AS Population, MAX(total_vaccinations) AS Total_Vaxxed
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
GROUP BY dea.location
ORDER BY population desc


-- Looking at percentage receiving vaccine dose
SELECT dea.continent, dea.location, MAX(dea.population) AS population, MAX(vac.total_vaccinations) AS total_vaxxed, 
( MAX(vac.total_vaccinations)/MAX(dea.population))*100 AS percentage_vaxxed
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
GROUP BY dea.continent, dea.location
ORDER BY MAX(dea.population) desc

-- use CTE
WITH PopVsVax (continent, location, date, population, new_vaccinations, rolling_ppl_vaxxed)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert (bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaxxed
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null 
)
SELECT *, (rolling_ppl_vaxxed/population)*100 AS rolling_percent_population_vaxxed
FROM PopVsVax

-- Temp Table

DROP TABLE IF EXISTS #PercentPopulationVaxxed
CREATE TABLE #PercentPopulationVaxxed
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_ppl_vaxxed numeric
)


INSERT INTO #PercentPopulationVaxxed
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert (bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaxxed
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null 
SELECT *, (rolling_ppl_vaxxed/population)*100 AS rolling_percent_population_vaxxed
FROM #PercentPopulationVaxxed

-- Creating view for later visuals

CREATE VIEW PercentPopulationVaxxed3 as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert (bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS rolling_ppl_vaxxed
FROM PortfolioProject_Covid..CovidDeaths dea
JOIN PortfolioProject_Covid..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null 

SELECT *
FROM PercentPopulationVaxxed3
