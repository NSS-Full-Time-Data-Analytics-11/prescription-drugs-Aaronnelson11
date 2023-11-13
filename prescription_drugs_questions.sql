-- QUestion 1. 
-- PART A. Which prescriber had the highest total number of claims 
-- (totaled over all drugs)? Report the npi and the total number of claims.
SELECT npi, SUM(total_claim_count)AS total_claim_count
FROM prescription
GROUP BY npi
ORDER BY total_claim_count DESC
LIMIT 1;


--   PART B. Repeat the above, but this time report the nppes_provider_first_name, 
--   nppes_provider_last_org_name,  specialty_description, and the total number
--   of claims.
SELECT prescription.npi, 
		nppes_provider_first_name AS first_name, 
		nppes_provider_last_org_name AS last_name, 
		specialty_description, 
		SUM(total_claim_count)AS total_claim_count
FROM prescription
INNER JOIN prescriber ON prescriber.npi = prescription.npi
GROUP BY prescription.npi, first_name, last_name, specialty_description
ORDER BY total_claim_count DESC
LIMIT 1;


-- Question2. 
-- PART A. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count)AS total_claims_from_all_drugs
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY total_claims_from_all_drugs DESC;


-- PART B. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count)AS total_claims_from_opioids
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE drug.opioid_drug_flag = 'Y'
GROUP BY specialty_description
ORDER BY total_claims_from_opioids DESC;


--  PART C. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no 
--   associated prescriptions in the prescription table?
SELECT specialty_description, COUNT(DISTINCT drug_name) AS number_of_prescriptions_per_specialty 
FROM prescriber
LEFT JOIN prescription USING(npi)
GROUP BY specialty_description
HAVING COUNT(DISTINCT drug_name) = 0
ORDER BY number_of_prescriptions_per_specialty;


--  PART D. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, 
--  report the percentage of total claims by that specialty which are for opioids. Which specialties have a 
--  high percentage of opioids?
WITH drug1 AS (SELECT specialty_description, SUM(total_claim_count) AS total_claim_count
				FROM prescriber
				INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
				WHERE drug.opioid_drug_flag = 'Y'
				GROUP BY specialty_description)
				-- ^ CTE to create table that sums total claims but only by opiods
SELECT drug1.specialty_description, ROUND(drug1.total_claim_count / SUM(prescription.total_claim_count)*100,2) AS percent_of_claims_from_opioids
FROM prescription
INNER JOIN prescriber USING(npi)
INNER JOIN drug1 USING(specialty_description)
GROUP BY drug1.specialty_description, drug1.total_claim_count
ORDER BY percent_of_claims_from_opioids DESC;
	
	  
-- Question 3. 
-- PART A. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost) AS total_drug_cost
FROM drug
FULL JOIN prescription USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY generic_name
ORDER BY total_drug_cost DESC
LIMIT 1;


-- PART B. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 
--  2 decimal places. Google ROUND to see how this works.**
SELECT DISTINCT(generic_name), ROUND(AVG(total_drug_cost)/AVG(total_day_supply),2) AS avg_total_cost_per_day 
FROM drug
FULL JOIN prescription USING(drug_name)
WHERE total_drug_cost IS NOT NULL
GROUP BY drug.generic_name
ORDER BY avg_total_cost_per_day DESC
LIMIT 1;


-- QUestion 4. 
-- PART A. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 
-- 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have 
--  antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs.
SELECT drug_name, 
	CASE WHEN opioid_drug_flag = 'Y' THEN 'opiod'
		 WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
	 	 ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_name;


--  PART B. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or 
--   on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	   CASE WHEN opioid_drug_flag = 'Y' THEN 'opioid'
	   		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
			ElSE 'neither' END AS drug_type,
	   SUM(total_drug_cost)::money AS total_cost_by_type
FROM drug INNER JOIN prescription USING (drug_name)
GROUP BY drug_type;

-- QUestion 5. 
--  PART A. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT COUNT(DISTINCT(cbsaname)) AS number_of_cbsa_in_tn FROM CBSA
WHERE cbsaname LIKE '%TN%'


-- b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
-- LARGEST COMBINED
SELECT cbsaname AS cbsa_name, SUM(population) AS population
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsa, cbsaname
ORDER BY population DESC
LIMIT 1

-- SMALLEST COMBINED
SELECT cbsaname AS cbsa_name, SUM(population) AS population
FROM cbsa
INNER JOIN population USING(fipscounty)
GROUP BY cbsa, cbsaname
ORDER BY population 
LIMIT 1


-- PART C. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.
SELECT county, population 
FROM population
INNER JOIN fips_county USING(fipscounty)
--^joined fips_county to get county names
LEFT JOIN cbsa USING(fipscounty)
WHERE cbsa IS NULL
--^only includes counties not included in CBSA
GROUP by county, population
ORDER BY population DESC
LIMIT 1;


-- QUestion 6. 
-- PART A. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.
SELECT drug_name, total_claim_count FROM prescription
WHERE total_claim_count >=3000
ORDER BY drug_name;

--PART B. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count, opioid_drug_flag AS opioid
FROM prescription
INNER JOIN drug USING(drug_name)
WHERE total_claim_count >=3000
ORDER BY drug_name;


-- PART C. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.
SELECT nppes_provider_last_org_name AS last_name, nppes_provider_first_name AS first_name, drug_name, total_claim_count, opioid_drug_flag AS opioid
FROM prescription
INNER JOIN prescriber USING(npi)
INNER JOIN drug USING(drug_name)
WHERE total_claim_count >=3000
ORDER BY last_name;


-- Question 7.
-- PART A. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Managment') in the city 
-- of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before 
-- running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT prescriber.npi, drug.drug_name 
FROM prescriber
CROSS JOIN drug 
WHERE specialty_description ILIKE 'Pain%' AND (nppes_provider_city = 'NASHVILLE') AND (opioid_drug_flag = 'Y')
GROUP BY prescriber.npi, drug.drug_name
ORDER BY prescriber.npi; 


--  PART B. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. 
--  You should report the npi, the drug name, and the number of claims (total_claim_count).
WITH drugs_1 AS (SELECT prescriber.npi, drug.drug_name 
				FROM prescriber
				CROSS JOIN drug 
				WHERE specialty_description ILIKE 'Pain%' AND (nppes_provider_city = 'NASHVILLE') AND (opioid_drug_flag = 'Y')
				GROUP BY prescriber.npi, drug.drug_name
				ORDER BY prescriber.npi) 
				--^used a CTE from the solution from PART A
SELECT npi, drugs_1.drug_name, SUM(total_claim_count) AS total_claim_count FROM drugs_1
LEFT JOIN prescription USING (NPI, drug_name)
GROUP BY drugs_1.npi, drugs_1.drug_name
ORDER BY npi;


--   c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.
WITH drugs_1 AS (SELECT prescriber.npi, drug.drug_name 
				FROM prescriber
				INNER JOIN prescription USING(npi)
				CROSS JOIN drug 
				WHERE specialty_description ILIKE 'Pain%' AND (nppes_provider_city = 'NASHVILLE') AND (opioid_drug_flag = 'Y')
				GROUP BY prescriber.npi, drug.drug_name
				ORDER BY prescriber.npi) 
				--^used a CTE from the solution from PART A
SELECT npi, drugs_1.drug_name, COALESCE(SUM(total_claim_count),0) AS total_claim_count FROM drugs_1
LEFT JOIN prescription USING (NPI, drug_name)
GROUP BY drugs_1.npi, drugs_1.drug_name
ORDER BY npi;

