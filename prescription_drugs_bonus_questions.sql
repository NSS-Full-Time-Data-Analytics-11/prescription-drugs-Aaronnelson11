-- Question 1. How many npi numbers appear in the prescriber table but not in the prescription table?
SELECT COUNT(DISTINCT(npi)) -(SELECT COUNT(DISTINCT(npi)) FROM prescription)AS number_of_npis_in_prescriber_but_not_prescription
FROM prescriber;


-- Question 2.
--PART A. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Family Practice.
SELECT generic_name, sum(total_claim_count) AS total_claim_by_drug
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE specialty_description ILIKE '%family practice%'
GROUP BY generic_name
ORDER BY total_claim_by_drug DESC
LIMIT 5;


--PART B. Find the top five drugs (generic_name) prescribed by prescribers with the specialty of Cardiology.
SELECT generic_name, sum(total_claim_count) AS total_claim_by_drug
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE specialty_description ILIKE '%cardiology%'
GROUP BY generic_name
ORDER BY total_claim_by_drug DESC
LIMIT 5;


--PART C. Which drugs are in the top five prescribed by Family Practice prescribers and Cardiologists? Combine what you did for parts a 
-- 	and b into a single query to answer this question.
WITH cte1 AS (SELECT generic_name, sum(total_claim_count) AS total_claim_count
				FROM prescriber
				INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
				WHERE specialty_description ILIKE '%family practice%'
				GROUP BY generic_name
				ORDER BY total_claim_count DESC),
				--^cte created from part A
	 cte2 AS (SELECT generic_name, sum(total_claim_count) AS total_claim_count
				FROM prescriber
				INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
				WHERE specialty_description ILIKE '%cardiology%'
				GROUP BY generic_name
				ORDER BY total_claim_count DESC)
				--cte created from part b
SELECT generic_name, CTE1.total_claim_count + CTE1.total_claim_count AS total_claims_by_drug
FROM cte1
FULL JOIN cte2 USING(generic_name)
WHERE CTE1.total_claim_count IS NOT NULL AND CTE1.total_claim_count IS NOT NULL
ORDER BY total_claims_by_drug DESC
LIMIT 5;


-- Question 3.
--Your goal in this question is to generate a list of the top prescribers in each of the major metropolitan areas of Tennessee.

--PART A. First, write a query that finds the top 5 prescribers in Nashville in terms of the total number of claims (total_claim_count) across 
-- 	all drugs. Report the npi, the total number of claims, and include a column showing the city.
SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber USING(npi)
WHERE nppes_provider_city ILIKE 'nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5;
	

--PART B. Now, report the same for Memphis.
SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber USING(npi)
WHERE nppes_provider_city ILIKE 'memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5;
    

--PART C. Combine your results from a and b, along with the results for Knoxville and Chattanooga.
(SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber USING(npi)
WHERE nppes_provider_city ILIKE 'chattanooga'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5)
--^top 5 claim by npi for chattanooga
UNION
(SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber  USING(npi)
WHERE nppes_provider_city ILIKE 'knoxville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5)
--^top 5 claim by npi for knoxville
UNION
(SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber  USING(npi)
WHERE nppes_provider_city ILIKE 'nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5)
--^top 5 claim by npi for nashville
UNION
(SELECT npi, SUM(total_claim_count)AS total_claim_count, nppes_provider_city 
FROM prescription
INNER JOIN prescriber  USING(npi)
WHERE nppes_provider_city ILIKE 'memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_claim_count DESC
LIMIT 5)
--^top 5 claim by npi for memphis
ORDER BY nppes_provider_city;


-- Question 4. Find all counties which had an above-average number of overdose deaths. Report the county name and number of overdose deaths.
WITH fips_county1 AS (SELECT county, state, fipscounty::INT ,fipsstate FROM fips_county)
					--^had to create a cte to  convert data type of fipscounty to INT so that it could be joined
SELECT  county, SUM(overdose_deaths)
FROM fips_county1
INNER JOIN overdose_deaths USING(fipscounty)
WHERE overdose_deaths > (SELECT AVG(overdose_deaths) FROM overdose_deaths)
GROUP BY county
ORDER BY county;


-- Question 5.
--PART A. Write a query that finds the total population of Tennessee.
 
SELECT SUM(population) AS total_population_of_TN FROM fips_county
INNER JOIN population USING(fipscounty)
WHERE state = 'TN';


--PART B. Build off of the query that you wrote in part a to write a query that returns for each county that county's name, its population,
-- 	and the percentage of the total population of Tennessee that is contained in that county.
SELECT county, population, (ROUND((population/ (SELECT SUM(population) AS total_population_of_TN FROM fips_county
												INNER JOIN population USING(fipscounty)
									  			WHERE state = 'TN'))*100,3)||'%') AS percent_of_TN_total_population
FROM fips_county
INNER JOIN population USING(fipscounty)
WHERE state = 'TN'


