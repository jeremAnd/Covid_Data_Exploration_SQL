-- Lets check out both tables
select * from covid_deaths cd;

select * from covid_vaccinations cv;

-- I used these lines to convert the date columns from varchar to date data types
/*ALTER TABLE covid_deaths  
ALTER COLUMN date TYPE date
using to_date(date, 'YYYY-MM-DD');

ALTER TABLE covid_vaccinations 
ALTER COLUMN date TYPE date
using to_date(date, 'YYYY-MM-DD');*/

-- Global cases, deaths, and death percentage
select sum(new_cases) as total_cases, sum(cast(new_deaths as int)) as total_deaths, 
sum(cast(new_deaths as int)*100.0)/sum(new_cases) as DeathPercentage
from covid_deaths
where continent != ' ' and new_cases != 0
order by 1,2;

-- Looking at Total Cases vs Total Deaths

select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percetage
from covid_deaths
order by 
location, 
date;

-- Lets take a look the U.S. death rate given you are infected with covid
select location, date, total_cases, total_deaths, (total_deaths*100.0/total_cases) as DeathPercentage
from covid_deaths
where location like '%States%'
order by 1,2;

-- Countries with highest rate of infection relative to population

select location, population, max(total_cases) as people_infected, max(total_cases*100.0/population) as percent_infected
from covid_deaths
group by location, population
order by percent_infected desc;

-- Showing Countries with Highest Death Count per population

select location, max(cast(total_deaths as int)) as TotalDeathCount
from covid_deaths
where continent != '' -- remove groupings for continents 
group by location
order by TotalDeathCount desc;


-- Lets create a table with useful columns, and a rolling vaccination total
-- here we will use a windows function to create rolling vaccination total
create table covid_data
as select cd.continent, cd."location", cd."date", cd.population, cd.total_cases, cd.new_cases, cd.total_deaths,
cd.new_deaths, cd.hosp_patients, cd.icu_patients, cv.total_tests, cv.male_smokers, cv.female_smokers, 
cv.positive_rate, cv.new_vaccinations, cv.total_vaccinations, cv.people_vaccinated, cv.people_fully_vaccinated,
aged_65_older, aged_70_older,
sum(cast( nullif(cv.new_vaccinations, '') as bigint)) over 
(partition by cd.location order by cd.location, cd.date) as rolling_vaccination
from covid_deaths cd 
join covid_vaccinations cv 
on cd."location" = cv."location" and
cd."date" = cv."date"
order by cd."location", cd."date";

-- How did vaccinations affect new cases
select continent, location, date, population, rolling_vaccination, new_cases
from 
covid_data
where continent != '' and new_cases != 0
order by location, date;

-- How did Vaccinations affect new deaths
select continent, location, date, population, rolling_vaccination, new_deaths
from 
covid_data
where continent != '' and new_deaths != 0
order by location, date;

-- How did coumtries with a larger smoking population share fare?
select location, max(female_smokers) as fem_smoker,  max(male_smokers) as male_smoker, 
max(total_deaths*100.0/population) as death_rate
from covid_data
where continent != '' and female_smokers != '' and male_smokers != '' and new_deaths != 0
group by location
order by death_rate desc;

-- Now lets check how countries with large shares of older populations fared
select location, max(aged_65_older) as aged_65_older, max(aged_70_older) as aged_70_older,
max(total_deaths*100.0/population) as death_rate
from covid_data
where aged_65_older != 0 and aged_70_older != 0 and totaL_deaths is not null
group by location
order by death_rate desc;


-- Now lets order countries by vaccination rates to see who did the best

-- Note: 
-- After doing some research, I found that Gibraltar vaccinated cross-border workers from Spain after vaccinating 
-- their own population, which explains why its vaccination rate is higher than 100 percent. This is likley the same 
-- for other small countries so we will treat values greater than 100 as 100 for the sake of this query.
select location, max(cast(nullif(people_vaccinated, '') as bigint)*100.0/population) as vaccination_rate
from covid_data
where continent != '' and people_vaccinated != ''
group by location
order by vaccination_rate desc;


-- Now lets create a view for visualization in tableau
create view covid_view as
select * from covid_data;







