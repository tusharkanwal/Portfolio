/*

Data exploration for gathering insights on COVID-19 data and assessing the situation and the impact COVID-19 had and where we are now.
I will be querying worldwide data as well as India's as that's the country where I reside and have been facing this pandemic for over 1.5 year hence, I would be delighted to gain further insights into the impact COVID

Skills used: Joins, CTE, Temp Tables, Views, AGG functions, Aliasing, coalesce, etc...
*/


--Query to see the complete data that is stored in the table(s) 

select * from portfolio.public.deaths 
where continent is not NULL 
order by 3,5;

select * from portfolio.public.vax 
where continent is not NULL 
order by 3,4;


-- Querying Data for India

select * from portfolio.public.deaths 
where location = 'India'
order by 4;

select * from portfolio.public.vax 
where location LIKE 'India' 
order by 4;


-- Viewing data that will be explored in this project

Select location,date,population,total_cases,new_cases,total_deaths
from portfolio.public.deaths
where continent is not NULL
order by location,date;


-- Total Cases vs Total Deaths / likelyhood of dying from covid (Worldwide)

Select location,date,total_cases,coalesce(total_deaths,NULL, 0) as total_deaths, coalesce((total_deaths/total_cases)*100,NULL,0) as death_percent
from portfolio.public.deaths
where continent is not null
order by location,date;


-- Total Cases vs Total Deaths / likelyhood of dying from covid (India)

Select location,date,total_cases,coalesce(total_deaths,NULL, 0) total_deaths, coalesce((total_deaths/total_cases)*100,NULL,0) as death_percent
from portfolio.public.deaths
where location = 'India'
order by location,date;


-- Total Cases vs Population / Percent of population who was infected (WorldWide)

Select location,date,population,total_cases,(total_cases/population)*100 as Infected_percent
from portfolio.public.deaths
where continent is not null
order by 1,2;


-- Total Cases vs Population / Percent of population who was infected (India)

Select location,date,population,total_cases,(total_cases/population)*100 as Infected_percent
from portfolio.public.deaths
where location = 'India'
order by 2;


-- Countries with highest infection rate compared to population 

Select location,population,coalesce(MAX(total_cases),NULL,0) as highest_infection_count,coalesce(MAX(total_cases/population),NULL,0)*100 as Infected_percent
from portfolio.public.deaths
where continent is not null
Group by location,population
order by Infected_percent desc;


-- Infection rate in India

Select location,population,coalesce(MAX(total_cases),NULL,0) as highest_infection_count,coalesce(MAX(total_cases/population),NULL,0)*100 as Infected_percent
from portfolio.public.deaths
where location ='India'
Group by location,population
order by Infected_percent desc;


-- Countries with highest death rate compared to population

Select location,coalesce(MAX(total_deaths),Null,0) as highest_death_count,coalesce(MAX(total_deaths/population),Null,0)*100 as death_percent
from portfolio.public.deaths
where continent is not null
Group by location
order by death_percent desc;


-- Death rate in India compared to population

Select location,coalesce(MAX(total_deaths),Null,0) as highest_death_count,coalesce(MAX(total_deaths/population),Null,0)*100 as death_percent
from portfolio.public.deaths
where location='India'
Group by location;


-- Continent wise breakdown
-- Total Deaths (worldwide)

Select continent,MAX(total_deaths) as highest_death_count
from portfolio.public.deaths
where continent is not null 
Group by continent
order by highest_death_count desc;


-- Total Deaths in India

Select location,MAX(total_deaths) as death_count
from portfolio.public.deaths
where location='India'
group by location;


-- Total cases, deaths and death percentage (worldwide)

Select  sum(new_cases) as Total_cases, sum(new_deaths) Total_deaths,sum(new_deaths)/sum(new_cases)*100 as death_percent
from portfolio.public.deaths
where continent is not null 
order by 1,2;


-- Total cases, deaths and Death Percentage in India

Select  sum(new_cases) as Total_cases, sum(new_deaths) Total_deaths,sum(new_deaths)/sum(new_cases)*100 as death_percent
from portfolio.public.deaths
where location='India';


-- Total Population vs Vaccinations
-- Population who has received atleast one vaccine dose (Worldwide)

select d.continent, d.location,d.date,d.population,coalesce(vax.new_vaccinations,NULL,0) new_vaccinations, sum(CAST(coalesce(vax.new_vaccinations,NULL,0) as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date
where d.continent is not null 
order by 2,3;


--Population who has received atleast one vaccine dose (India)

select v.location,v.date,d.population ,coalesce(v.new_vaccinations,NULL,0) new_vaccinations
From  portfolio.public.vax as v
join portfolio.public.deaths as d
on d.location=v.location
where d.location like 'India' 
order by 2;


-- CTE

-- % of population who has received atleast one vaccine dose(Worldwide)

With PopVsVax 
(Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
			   as
			   (select d.continent, d.location,d.date,d.population,coalesce(vax.new_vaccinations,Null,0) new_vaccinations, sum(CAST(coalesce(vax.new_vaccinations,Null,0) as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date
where d.continent is not null 
--order by 2,3;
)

Select * ,coalesce((rollingpeoplevaccinated/population),null,0)*100 as Percent_Vaccinated
from popvsvax;


-- % of population who has received atleast one vaccine dose(India)

With PopVsVaxInd
(location, date, population, new_vaccinations, RollingPeopleVaccinated)
			   as			   
				  (select  d.location,d.date,d.population,coalesce(vax.new_vaccinations,null,0), sum(CAST(coalesce(vax.new_vaccinations,null,0) as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date
where d.continent is not null 
--order by 2,3;
)

Select * ,coalesce((rollingpeoplevaccinated/population),Null,0)*100 as Percent_Vaccinated
from popvsvaxInd
where location ='India';


-- Temp Table

drop table if exists Percent_population_vaccinated;

create temp table Percent_Population_vaccinated (
	continent varchar(255), location varchar(255), date date, population bigint, new_vaccinations bigint, RollingPeopleVaccinated bigint
);

insert into Percent_population_vaccinated
select d.continent, d.location,d.date,d.population,coalesce(vax.new_vaccinations,Null,0), sum(CAST(coalesce(vax.new_vaccinations,null,0) as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date;

Select * ,coalesce((rollingpeoplevaccinated/population),null,0)*100 as Percent_Vaccinated
from Percent_Population_vaccinated;


-- View for viz (Worldwide)

create view Percent_population_vaccinated as 
select d.continent, d.location,d.date,d.population,vax.new_vaccinations, sum(CAST(vax.new_vaccinations as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date
where d.continent is not null ;


-- View for Viz (India)

create view Percent_population_vaccinated_Ind as 
select d.location,d.date,d.population,vax.new_vaccinations, sum(CAST(vax.new_vaccinations as bigint)) OVER (partition by d.location order by d.location, d.date) as RollingPeopleVaccinated
From portfolio.public.deaths as d 
join portfolio.public.vax on d.location=vax.location 
and d.date=vax.date
where d.location like 'India';

