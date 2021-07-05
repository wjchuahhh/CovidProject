select * from Covid.dbo.CovidDeaths$
order by 3,4

-- Select Data that we are going to be using for reviewing purposes
select location, date, total_cases, new_cases, total_deaths, population
from Covid..CovidDeaths$
order by 1,2

-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in Singapore
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
where location like 'Singapore'
order by date

-- Looking at the Total Cases vs Population
-- shows likelihood of getting Covid in Singapore
select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
from Covid..CovidDeaths$
where location like 'Singapore'
order by date

-- Looking at countries with highest daily Infection Rate compared to Population
-- shows location with highest infection rate
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases)/population)*100 as HighestInfectionRate
from Covid..CovidDeaths$
group by location, population
order by HighestInfectionRate desc

-- Looking at countries with highest death rates
select location, population, max((total_deaths)/population)*100 as HighestDeathRate
from Covid..CovidDeaths$
group by location, population
order by HighestDeathRate desc

-- Looking at countries with highest total death count
-- data type of total_deaths is 'nvarchar' which does not allow SUM to be performed. We have to make use of CAST.
-- we have to remove locations which appears to be continents instead as well
select location, max(cast(total_deaths as int)) as DeathCount
from Covid..CovidDeaths$
where continent is not NULL
group by location
order by DeathCount desc

-- Looking at number of new cases and deaths per day for the entire world
-- data type of new_deaths is 'nvarchar' which does not allow SUM to be performed. We have to make use of CAST.
select date, sum(new_cases) as DailyNewCases, sum(cast(new_deaths as int)) as DailyNewDeaths
from Covid..CovidDeaths$
group by date
order by date

-- Looking at number of people vaccinated in the countries' population
-- using windows SUM function to do a rolling sum of new vaccinations >> result is the same as total_vaccination column available in data
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from Covid..CovidVaccinations$
where continent is not NULL

-- Use CTE to create table and then use the fields in the CTE table created for calculation
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
as
(
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from Covid..CovidVaccinations$
where continent is not NULL
)
select *, (Total_Vaccinations/Population)*100 as PercentageVaccinated
from PopvsVac

-- Use temp table (should return same result as using CTE from above)
-- have to specify data type
drop table if exists #PercentPopulationVaccinated -- this step makes it convenient to make alterations to the table
create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population int,
New_Vaccinations int,
Total_Vaccinations int
)

insert into #PercentPopulationVaccinated
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from Covid..CovidVaccinations$
where continent is not NULL

select *, (Total_Vaccinations/Population)*100 as PercentageVaccinated
from #PercentPopulationVaccinated

-- Creating Views to store data for visualization later
-- 1
create view DeathPercentageSG as
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from Covid..CovidDeaths$
where location like 'Singapore'

-- 2
create view InfectionRateSG as
select location, date, total_cases, population, (total_cases/population)*100 as InfectionRate
from Covid..CovidDeaths$
where location like 'Singapore'

-- 3
create view GlobalInfectionRate as
select location, population, max(total_cases) as HighestInfectionCount, max((total_cases)/population)*100 as HighestInfectionRate
from Covid..CovidDeaths$
group by location, population

-- 4
create view GlobalDeathRate as
select location, population, max((total_deaths)/population)*100 as HighestDeathRate
from Covid..CovidDeaths$
group by location, population

-- 5 
create view GlobalDeathCount as
select location, max(cast(total_deaths as int)) as DeathCount
from Covid..CovidDeaths$
where continent is not NULL
group by location

-- 6
create view RollingVaccination as
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from Covid..CovidVaccinations$
where continent is not NULL

-- 7
create view PercentPopulationVaccinated as
with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Total_Vaccinations)
as
(
select continent, location, date, population, new_vaccinations, sum(cast(new_vaccinations as int)) OVER (PARTITION BY location ORDER BY location, date) as total_vaccination
from Covid..CovidVaccinations$
where continent is not NULL
)
select *, (Total_Vaccinations/Population)*100 as PercentageVaccinated
from PopvsVac