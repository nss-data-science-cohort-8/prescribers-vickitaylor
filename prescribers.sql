-- ## Prescribers Database

-- For this exericse, you'll be working with a database derived from the [Medicare Part D Prescriber Public Use File](https://www.hhs.gov/guidance/document/medicare-provider-utilization-and-payment-data-part-d-prescriber-0). More information about the data is contained in the Methodology PDF file. See also the included entity-relationship diagram.

-- 1. 
--     a. Which prescriber had the highest total number of claims (totaled over all drugs)? Report the npi and the total number of claims.

SELECT 
	npi, 
	SUM(total_claim_count) AS TotalClaims
FROM prescription
GROUP BY npi
ORDER BY 2 DESC
LIMIT 1


--     b. Repeat the above, but this time report the nppes_provider_first_name, nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT 
	p.npi,
	d.nppes_provider_first_name,
	d.nppes_provider_last_org_name, 
	d.specialty_description, 
	SUM(p.total_claim_count) AS TotalClaims
FROM prescription AS p
LEFT JOIN prescriber AS d
	ON p.npi = d.npi
GROUP BY p.npi, d.nppes_provider_first_name, d.nppes_provider_last_org_name, d.specialty_description
ORDER BY 2 DESC
LIMIT 1

-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT 
	d.specialty_description,
	SUM(p.total_claim_count) AS TotalClaims
FROM prescriber AS d
LEFT JOIN prescription AS p
	ON d.npi = p.npi
GROUP BY d.specialty_description
ORDER BY 2 DESC NULLS LAST
LIMIT 1

--     b. Which specialty had the most total number of claims for opioids?
SELECT 
	d.specialty_description,
	SUM(p.total_claim_count) AS TotalClaims
FROM prescriber AS d
LEFT JOIN prescription AS p
	ON d.npi = p.npi
INNER JOIN drug AS g
	ON p.drug_name = g.drug_name
WHERE opioid_drug_flag = 'Y'
GROUP BY d.specialty_description
ORDER BY 2 DESC NULLS LAST
LIMIT 1

--     c. **Challenge Question:** Are there any specialties that appear in the prescriber table that have no associated prescriptions in the prescription table?
SELECT DISTINCT 
	d.specialty_description
FROM prescriber AS d
EXCEPT
SELECT DISTINCT
	d.specialty_description
FROM prescriber AS d
INNER JOIN prescription AS p
	ON d.npi = p.npi

-- other way 
SELECT DISTINCT 
	specialty_description
FROM prescriber
WHERE specialty_description NOT IN (SELECT DISTINCT d.specialty_description FROM prescriber AS d INNER JOIN prescription 	AS p ON d.npi = p.npi)
	
--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* For each specialty, report the percentage of total claims by that specialty which are for opioids. Which specialties have a high percentage of opioids?


-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT 
	d.generic_name, 
	p.total_drug_cost
FROM drug AS d
INNER JOIN prescription AS p
	ON d.drug_name = p.drug_name
ORDER BY 2 DESC
LIMIT 1

--     b. Which drug (generic_name) has the hightest total cost per day? **Bonus: Round your cost per day column to 2 decimal places. Google ROUND to see how this works.**
SELECT 
	d.generic_name, 
	ROUND(p.total_drug_cost / 360, 2) AS CostPerDay
FROM drug AS d
INNER JOIN prescription AS p
	ON d.drug_name = p.drug_name
ORDER BY 2 DESC
LIMIT 1

-- 4. 
--     a. For each drug in the drug table, return the drug name and then a column named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 'neither' for all other drugs. **Hint:** You may want to use a CASE expression for this. See https://www.postgresqltutorial.com/postgresql-tutorial/postgresql-case/ 
SELECT 
	drug_name,
	CASE
		WHEN opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type
FROM drug

--     b. Building off of the query you wrote for part a, determine whether more was spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total costs as MONEY for easier comparision.
SELECT 
	drug_type, 
	CAST(SUM(TotalCost) AS MONEY) AS TotalCost
FROM (SELECT 
	CASE
		WHEN d.opioid_drug_flag = 'Y' THEN 'opioid'
		WHEN d.antibiotic_drug_flag = 'Y' THEN 'antibiotic'
		ELSE 'neither'
	END AS drug_type, 
	CAST(p.total_drug_cost AS MONEY) AS TotalCost
	FROM drug AS d
	INNER JOIN prescription AS p
		ON d.drug_name = p.drug_name
	)
WHERE drug_type IN ('opioid', 'antibiotic')
GROUP BY drug_type
ORDER BY 2 DESC


-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT 
	COUNT(*)
FROM cbsa AS c
INNER JOIN fips_county AS f
	ON c.fipscounty = f.fipscounty
WHERE f.state = 'TN'


--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.

SELECT 
	cbsa, 
	SUM(population) AS TotalPopulation
FROM cbsa AS c
INNER JOIN population AS p
	ON c.fipscounty = p.fipscounty
GROUP BY cbsa
ORDER BY 2

--     c. What is the largest (in terms of population) county which is not included in a CBSA? Report the county name and population.

SELECT 
	fipscounty, 
	SUM(population) AS TotalPop
FROM population
GROUP BY fipscounty
EXCEPT
SELECT 
	c.fipscounty, 
	SUM(p.population) AS TotalPop
FROM cbsa AS c
INNER JOIN population AS p
	ON c.fipscounty = p.fipscounty
GROUP BY c.fipscounty
ORDER BY 2 DESC
LIMIT 1

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000. Report the drug_name and the total_claim_count.


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.

--     c. Add another column to you answer from the previous part which gives the prescriber first and last name associated with each row.

-- 7. The goal of this exercise is to generate a full list of all pain management specialists in Nashville and the number of claims they had for each opioid. **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists (specialty_description = 'Pain Management) in the city of Nashville (nppes_provider_city = 'NASHVILLE'), where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it. You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).
    
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. Hint - Google the COALESCE function.