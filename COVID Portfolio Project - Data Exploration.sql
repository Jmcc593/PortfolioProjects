/*
	Covid-19 Data Exploration

	Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/




--SELECT DATA THAT WE ARE GOING TO USE

SELECT Location,
	date,
	Total_cases,
	New_cases,
	Total_deaths,
	Population
FROM ProjectDB..CovidDeaths
ORDER BY 1,2




-- Looking at total cases vs total deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT Location,
	date,
	Total_cases,
	Total_deaths,
	(Total_deaths/Total_cases)*100 AS Death_percentage
FROM ProjectDB..CovidDeaths
WHERE Location LIKE '%states%'
ORDER BY 1,2




-- Looking at total cases vs population
-- Shows what percentage of population infected with covid

SELECT Location,
	date,
	Population,
	Total_cases,
	(Total_cases/Population)*100 AS Percent_population_infected
FROM ProjectDB.Dbo.CovidDeaths
ORDER BY 1,2




-- Countries with highest infection rate per population

SELECT Location,
	Population,
	max(Total_cases) AS Highest_infection_count,
	max((Total_cases/Population))*100 AS Percent_population_infected
FROM ProjectDB.Dbo.CovidDeaths
GROUP BY Location,Population
ORDER BY Percent_population_infected DESC




-- Countries with highest death count per population

SELECT Location,
	max(cast(Total_deaths AS int)) AS Total_death_Count
FROM ProjectDB.Dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Location
ORDER BY Total_death_count DESC





-- LET'S BREAK THINGS DOWN BY CONTINENT --

-- Showing continents with the highest death count per population

SELECT Continent,
	max(cast(Total_deaths AS int)) AS Total_death_Count
FROM ProjectDB.Dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY Continent
ORDER BY Total_death_count DESC




-- GLOBAL NUMBERS (TOTAL CASES / TOTAL DEATHS / DEATH PERCENTAGE)

SELECT sum(New_cases) AS Total_cases,
	sum(cast(New_deaths AS int)) AS Total_deaths,
	sum(cast(New_deaths AS int))/sum(New_cases)*100 AS Death_percentage
FROM ProjectDB..CovidDeaths
WHERE Continent IS NOT NULL
ORDER BY 1,2




-- Total Population vs Vaccinations

SELECT Dea.Continent,
	Dea.Location,
	Dea.date,
	Dea.Population,
	Vac.New_vaccinations,
	sum(convert(int,Vac.New_vaccinations)) OVER (Partition BY Dea.Location ORDER BY Dea.Location,Dea.date) AS Rolling_people_vaccinated
FROM ProjectDB.Dbo.CovidDeaths Dea
		JOIN 
		ProjectDB.Dbo.CovidVaccinations Vac
		ON Dea.Location = Vac.Location AND
		Dea.date = Vac.date
WHERE Dea.Continent IS NOT NULL
ORDER BY 2,3





--  Using CTE to perform Calculation on Partition By previous query

WITH Pop_vs_vac (Continent,Location,date,Population,New_vaccinations,Rolling_people_vaccinated) AS ( SELECT Dea.Continent,Dea.Location,Dea.date,Dea.Population,Vac.New_vaccinations,sum(convert(int,Vac.New_vaccinations)) OVER (Partition BY Dea.Location ORDER BY Dea.Location,Dea.date) AS Rolling_people_vaccinated FROM ProjectDB.Dbo.CovidDeaths Dea JOIN ProjectDB.Dbo.CovidVaccinations Vac ON Dea.Location = Vac.Location AND Dea.date = Vac.date WHERE NOT(Dea.Continent IS NULL) ) SELECT *,
	(Rolling_people_vaccinated/Population)*100
FROM Pop_vs_vac




-- Using Temp Table to perform Calculation on Partition By in previous query

DROP table IF EXISTS #PercentPopulationVaccinated
CREATE table #PercentPopulationVaccinated
(
	Continent nvarchar(255),
	Location nvarchar(255),
	date datetime,
	Population numeric,
	New_vaccinations numeric,
	Rolling_people_vaccinated numeric 
)

INSERT INTO #PercentPopulationVaccinated 
SELECT 
	Dea.Continent,
	Dea.Location,
	Dea.date as date,
	Dea.Population,
	Vac.New_vaccinations,
	SUM(convert(int,Vac.New_vaccinations)) OVER (Partition BY Dea.Location ORDER BY Dea.Location,Dea.date) AS Rolling_people_vaccinated
FROM ProjectDB..CovidDeaths Dea JOIN ProjectDB..CovidVaccinations Vac ON Dea.Location = Vac.Location AND Dea.date = Vac.date
SELECT *, (Rolling_people_vaccinated/Population)*100
FROM #PercentPopulationVaccinated




-- Creating view to store data for later visualizations

Create View PercentPopulationVaccinatedView as
Select 
	dea.continent,
	dea.location,
	dea.date,
	dea.population,
	vac.new_vaccinations,
	SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.Location, dea.Date) as rolling_people_vaccinated
From ProjectDB.dbo.CovidDeaths dea
join ProjectDB.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null



-- Run the view we just created

Select *
From PercentPopulationVaccinatedView