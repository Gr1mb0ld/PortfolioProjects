SELECT *
FROM PortfolioProject..CovidDeaths
where location = 'Upper middle income'
order by 3,4

/*
SELECT *
FROM PortfolioProject..CovidVaccination
order by 3,4
*/

--Select data that we are going to be using

Select location, date, total_cases, new_cases, total_deaths, population
From PortfolioProject..CovidDeaths
order by 1,2


-- Looking at the Total Cases vs Total Deaths
-- shows likelihood of dying if you cintract covid in your country
Select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
From PortfolioProject..CovidDeaths
Where continent is not null and location = 'Hungary'
order by 1,2


-- Looking at the Total Cases vs Population
--Shows what percentage of population got covid
Select location, date, total_cases, population, (total_cases/population)*100 AS PercentPopulationInfected
From PortfolioProject..CovidDeaths
Where continent is not null and (total_cases/population)*100 > 0.0001 and location = 'Hungary'
--Where Location like '%states%'
order by 1,2


-- Looking at Countries with Highest Infection Rate compared to Population

Select location, population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 AS
PercentPopulationInfected, MAX(total_deaths) MaxDeath
From PortfolioProject..CovidDeaths
--Where Location = 'Hungary'
Where continent is not null
Group by location, population
order by PercentPopulationInfected desc


--Showing Countries with Highest Deatcount per Population
Select location, population, MAX(total_deaths) TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is not null
Group by location, population
order by TotalDeathCount desc

--Break things down by continent with the highest deathcount

Select location, MAX(total_deaths) TotalDeathCount
From PortfolioProject..CovidDeaths
Where continent is null and location not in ('World', 'High income', 'Upper middle income', 'Lower middle income', 'European Union', 'Low income')
Group by location
order by TotalDeathCount desc

-- Global numbers

SELECT date, SUM(new_cases) TotalNewCases, sum(new_deaths) TotalNewDeaths , Sum(new_deaths)/NULLIF(Sum(new_cases), 0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent is not null
Group by date
order by 1,2

--by removing date we got Grand Total
SELECT SUM(new_cases) TotalNewCases, sum(new_deaths) TotalNewDeaths , Sum(new_deaths)/NULLIF(Sum(new_cases), 0)*100 as DeathPercentage
FROM PortfolioProject..CovidDeaths
where continent is not null
--Group by date
order by 1,2


-- Looking at Total Population vs Vaccinations
-- cant use a computed(temporary) column to make a new one

SELECT dea.continent, Dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location
, dea.date) as RollingTotalVac,-- RollingTotalVac/population*100
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccination Vac
	ON Dea.location = Vac.location
	and Dea.date = Vac.date
Where dea.continent is not Null
order by 2,3

-- use cte -- need to have the same amount of column in the CTE then in the calculation below

With PopvsVac(Continent, Location, Date, Population, new_vaccinations, RollingTotalVac)
as
(
SELECT dea.continent, Dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location
, dea.date) as RollingTotalVac--, RollingTotalVac/population*100
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccination Vac
	ON Dea.location = Vac.location
	and Dea.date = Vac.date
Where dea.continent is not Null
--order by 2,3
)
Select *, RollingTotalVac/population*100
From PopvsVac

--TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingTotalVac numeric
)

Insert Into #PercentPopulationVaccinated
SELECT dea.continent, Dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location
, dea.date) as RollingTotalVac--, RollingTotalVac/population*100
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccination Vac
	ON Dea.location = Vac.location
	and Dea.date = Vac.date
--Where dea.continent is not Null
--order by 2,3

Select *, RollingTotalVac/population*100 as VaccinationRate
From #PercentPopulationVaccinated


-- Createing view to store data for later visualization

Create View PercentPopulationVaccinated as
SELECT dea.continent, Dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location order by dea.location
, dea.date) as RollingTotalVac--, RollingTotalVac/population*100
FROM PortfolioProject..CovidDeaths Dea
Join PortfolioProject..CovidVaccination Vac
	ON Dea.location = Vac.location
	and Dea.date = Vac.date
Where dea.continent is not Null
--order by 2,3

SELECT *
FROM PercentPopulationVaccinated