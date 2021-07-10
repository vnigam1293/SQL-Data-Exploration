/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Exploring imported datasets

select *
from PortfolioProject..CovidDeaths
where continent is not null
order by 3, 4

--select *
--from PortfolioProject..CovidVaccinations
--order by 3, 4

-- Select Data that we are going to be using

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
where continent is not null
order by 1, 2

-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract Covid in your country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from PortfolioProject..CovidDeaths
where location like '%states%'
and continent is not null
order by 1, 2

-- Total Cases vs Population
-- Shows what percentage of population got Covid
select location, date, population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
where continent is not null
-- where location like '%states%'
order by 1, 2

-- Countries with Highest Infection Rate compared to Population

select location, population, max(total_cases) as HighestInfectionCount, max((total_cases/population))*100 as PercentPopulationInfected
from PortfolioProject..CovidDeaths
-- where location like '%states%'
where continent is not null
group by location, population
order by PercentPopulationInfected desc

-- Countries with Highest Death Count per Population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
-- where location like '%states%'
where continent is not null
group by location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject..CovidDeaths
-- where location like '%states%'
where continent is not null
group by continent
order by TotalDeathCount desc

-- GLOBAL NUMBERS

select date, sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as DeathPercentage
from PortfolioProject..CovidDeaths
-- where location like '%states%'
where continent is not null
group by date
order by 1, 2

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths cd
join PortfolioProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
order by 2, 3

-- Using CTE to perform Calculation on Partition By in 'Total Population vs Vaccinations' query

with PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated)
as
(
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths cd
join PortfolioProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac

-- Using Temp Table to perform Calculation on Partition By in 'Total Population vs Vaccinations' query

drop table if exists #PercentPopulationVaccinated
Create table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime, 
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

insert into #PercentPopulationVaccinated
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths cd
join PortfolioProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null
-- order by 2, 3

select *, (RollingPeopleVaccinated/Population)*100
from #PercentPopulationVaccinated

-- Creating View to store data for later visualizations

create view PercentPopulationVaccinated as 
select cd.continent, cd.location, cd.date, cd.population, cv.new_vaccinations, 
sum(convert(int, cv.new_vaccinations)) over (partition by cd.location order by cd.location, cd.date) as RollingPeopleVaccinated
from PortfolioProject..CovidDeaths cd
join PortfolioProject..CovidVaccinations cv
	on cd.location = cv.location
	and cd.date = cv.date
where cd.continent is not null

select *
from PercentPopulationVaccinated