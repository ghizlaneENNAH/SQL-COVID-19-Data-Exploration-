SELECT * FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

-- select the data that we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- looking for total cases vs total deaths

SELECT location, SUM(total_cases) AS total_cases, SUM(total_deaths) AS total_deaths
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY 1

-- looking for the percentage of deaths among the infected people
-- shows likelihood of death if you contract COVID in your country

SELECT location, date, total_cases, new_cases, total_deaths,
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM [CovidAnalysisDB]..CovidDeaths
WHERE location LIKE '%States%' AND continent IS NOT NULL
ORDER BY 1,2

-- Looking at total Cases vs population
-- shows what percentage of population got COVID

SELECT location, date, total_cases, population,
       (total_cases / population) * 100 AS PercentPopulationInfect
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- countries with highest infection rate compared to population

SELECT location, population,
       MAX(total_cases) AS HighestInfectionCountry,
       MAX((total_cases / population) * 100) AS PercentPopulationInfect
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY PercentPopulationInfect DESC

-- countries with the highest death percentage 

SELECT location, population,
       MAX(total_deaths / population) * 100 AS percentageOfDeathsCases
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percentageOfDeathsCases DESC

-- countries with the highest death count per population

SELECT location, population,
       MAX(CAST(total_deaths AS INT)) AS highestDeathsCount
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highestDeathsCount DESC

-- CONTINENT LEVEL

-- Continents with highest death count per population

SELECT continent,
       MAX(CAST(total_deaths AS INT)) AS highestDeathsCount
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY highestDeathsCount DESC

-- show continents that are inserted as countries

SELECT location,
       MAX(CAST(total_deaths AS INT)) AS highestDeathsCount
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY highestDeathsCount DESC

-- GLOBAL NUMBERS

SELECT date,
       SUM(new_cases) AS total_cases,
       SUM(CAST(new_deaths AS INT)) AS total_deaths,
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2

-- across the world (overall)

SELECT SUM(new_cases) AS total_cases,
       SUM(CAST(new_deaths AS INT)) AS total_deaths,
       (SUM(CAST(new_deaths AS INT)) / SUM(new_cases)) * 100 AS DeathPercentage
FROM [CovidAnalysisDB]..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

-- total population vs vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RoolingPeopleVaccinated
FROM [CovidAnalysisDB]..CovidDeaths dea
JOIN [CovidAnalysisDB]..CovidVaccinations vac
  ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3

-- use CTE for calculating percentage vaccinated

WITH PopVsVac (continent, location, date, population, new_vaccinations, RoolingPeopleVaccinated)
AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RoolingPeopleVaccinated
    FROM [CovidAnalysisDB]..CovidDeaths dea
    JOIN [CovidAnalysisDB]..CovidVaccinations vac
      ON dea.location = vac.location
     AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RoolingPeopleVaccinated / population) * 100
FROM PopVsVac;

-- TEMP TABLE for vaccination %

CREATE TABLE #PercentPopulationVaccinated
(
  continent NVARCHAR(255),
  location NVARCHAR(255),
  date DATETIME,
  population NUMERIC,
  new_vaccinations NUMERIC,
  RoolingPeopleVaccinated NUMERIC
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RoolingPeopleVaccinated
FROM [CovidAnalysisDB]..CovidDeaths dea
JOIN [CovidAnalysisDB]..CovidVaccinations vac
  ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT *, (RoolingPeopleVaccinated / population) * 100
FROM #PercentPopulationVaccinated

-- CREATE VIEW for Power BI

CREATE VIEW PercentPopulationVaccinatedV AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(vac.new_vaccinations AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RoolingPeopleVaccinated
FROM [CovidAnalysisDB]..CovidDeaths dea
JOIN [CovidAnalysisDB]..CovidVaccinations vac
  ON dea.location = vac.location
 AND dea.date = vac.date
WHERE dea.continent IS NOT NULL

SELECT * FROM PercentPopulationVaccinatedV
