ALTER TABLE covid_vaccinationcsv ALTER COLUMN date TYPE DATE 
USING to_date(date, 'DD/MM/YYYY');

SELECT location, continent, date, total_cases, new_cases, total_deaths, population
FROM covid_deathscsv
WHERE location='international'
ORDER BY 1;

-- looking at total cases vs total deaths
--showing what percentage of cases resulted in deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/ total_cases) *100 AS death_percentage
FROM covid_deathscsv
ORDER BY 1,2;

-- looking at total cases vs population
--showing what percentage of population were infected
SELECT location,date,total_cases,population, (total_cases/population)*100 AS case_rate
FROM covid_deathscsv
ORDER BY 1,2;

--looking at countries with highest infection rate
SELECT location, MAX(total_cases) AS HighestInfectionCountRate, population, MAX((total_cases/population))*100 AS case_rate
FROM covid_deathscsv
where continent IS NOT null and total_cases IS NOT null
GROUP BY location, population
ORDER BY case_rate DESC;

--showing countries with Highest Death Count per population
SELECT location, MAX(total_deaths) AS HighestDeathCountRate, population, MAX((total_deaths/population))*100 as death_rate
FROM covid_deathscsv
WHERE continent IS NOT null AND total_deaths IS NOT null
GROUP BY location,population
ORDER BY death_rate DESC;

--Lets break things down by continent
--showing continent with Highest Death Count per population
SELECT continent, MAX(total_deaths) AS HighestDeathCountRate
FROM covid_deathscsv
WHERE continent IS NOT null AND total_deaths IS NOT null
GROUP BY continent
ORDER BY HighestDeathCountRate DESC;

--Global Numbers
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, (SUM(new_deaths)/SUM(new_cases))*100 AS death_percentage
FROM covid_deathscsv
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1;

--showing total population vs vaccination
WITH popVSvac(continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
AS
(
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location,d.date) as RollingPeopleVaccinated
FROM covid_deathscsv d
JOIN covid_vaccinationcsv v
ON d.location =v.location AND d.date=v.date
WHERE d.continent IS NOT null
ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 as Vaccine_rate
from popVSvac

--Using Temp Tables
DROP TABLE IF EXISTS percentPopulationVaccinated;
CREATE TEMP TABLE percentPopulationVaccinated
(
continent varchar(255),
location varchar(255),
date TIMESTAMP,
population numeric,
new_vaccinations numeric,
RollingPeopleVaccinated numeric
);
INSERT INTO percentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location,d.date) as RollingPeopleVaccinated
FROM covid_deathscsv d
JOIN covid_vaccinationcsv v
ON d.location =v.location AND d.date=v.date
WHERE d.continent IS NOT null;

SELECT *, (RollingPeopleVaccinated/population)*100 as Vaccine_rate
from percentPopulationVaccinated;

--creating view to store data for later visualization
CREATE VIEW percentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location,d.date) as RollingPeopleVaccinated
FROM covid_deathscsv d
JOIN covid_vaccinationcsv v
ON d.location =v.location AND d.date=v.date
WHERE d.continent IS NOT null;


-- codes for tableau
select SUM(v.new_cases) AS new_cases,MAX(v.total_cases) AS total_cases,
	SUM(v.new_vaccinations)AS new_vaccinations, MAX(v.total_vaccinations) AS total_vaccinations,
	SUM(d.new_deaths) AS new_deaths,MAX(d.total_deaths) AS total_deaths, v.date
from covid_vaccinationcsv v
JOIN covid_deathscsv d
ON v.date=d.date and d.location = v.location
Where d.location = 'World'
group by v.date
order by v.date;



SELECT v.location, v.date, v.new_vaccinations, SUM(v.new_vaccinations) OVER (PARTITION BY v.location ORDER BY v.location,v.date) as RollingPeopleVaccinated, 
	d.new_deaths,SUM(d.new_deaths) OVER (PARTITION BY d.location ORDER BY d.location,d.date) as RollingPeopledeaths, 
	d.new_cases, SUM(d.new_cases) OVER (PARTITION BY d.location ORDER BY d.location,d.date) as RollingNewCases
FROM covid_vaccinationcsv v
JOIN covid_deathscsv d
ON v.location = d.location AND v.date = d.date
WHERE d.continent IS NOT null;

SELECT location, continent, population, MAX(total_cases) AS highestinfectioncount, ( MAX(total_cases)/population)*100 AS percentpopulationinfected
FROM covid_deathscsv
WHERE continent IS NOT null
GROUP BY 1,2,3
ORDER BY 1,3;