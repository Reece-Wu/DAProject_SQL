-- 1. Observe key statistics on average wage

SELECT MAX(ave_weekly_wage) AS max_avewage,
	   AVG(ave_weekly_wage) AS avg_avewage,
	   MIN(ave_weekly_wage) AS min_avewage,
	   PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY ave_weekly_wage) AS per25_avewage,
	   PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY ave_weekly_wage) AS med_avewage,
	   PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY ave_weekly_wage) AS per75_avewage
FROM wages;

-- 2. Comparison of average wage in the past five years

SELECT y.year, AVG(w.ave_weekly_wage) AS average
FROM wages w
INNER JOIN years y
	ON w.year_id = y.year_id
GROUP BY y.year
ORDER BY y.year;

-- 3. Ranking of average weekly wage by province

SELECT p.province, AVG(w.ave_weekly_wage) AS ave_wage
FROM wages w
INNER JOIN provinces p
	ON w.province_id = p.province_id
GROUP BY p.province
ORDER BY ave_wage DESC;

-- 4. Wage changes in the highest population province 'Ontario' by year

SELECT y.year, AVG(w.ave_weekly_wage) AS Ontario_wave_wage
FROM wages w
INNER JOIN years y
	ON w.year_id = y.year_id
WHERE w.province_id = (SELECT province_id FROM provinces WHERE province = 'Ontario')
GROUP BY y.year
ORDER BY y.year;

-- 5. Wage levels by gender and age group

SELECT p.sex, p.age, AVG(w.ave_weekly_wage) AS ave_wage
FROM wages w
INNER JOIN profiles p 
	ON w.profile_id = p.profile_id
GROUP BY p.sex, p.age
ORDER BY ave_wage DESC;

-- 6. Comparison of gender wage levels by age group

WITH wage_gender AS(
SELECT p.sex, p.age, AVG(w.ave_weekly_wage) AS ave_wage
FROM wages w
INNER JOIN profiles p 
	ON w.profile_id = p.profile_id
GROUP BY p.sex, p.age
)
SELECT AVG(wm.ave_wage / ww.ave_wage) AS gender_wage_ratio
FROM (
	SELECT *
	FROM wage_gender
	WHERE sex = 'Males'
	) AS wm
INNER JOIN wage_gender ww
	ON wm.age = ww.age
WHERE ww.sex = 'Females';

-- 7. Ranking of full-time occupations by average weekly wage

SELECT ot.occupation, AVG(w.ave_weekly_wage) AS ave_wage
FROM (
	SELECT o.occupation_id, o.occupation, w.worktype
	FROM occupations o
	INNER JOIN worktypes w
		ON o.worktype_id = w.worktype_id
	WHERE w.worktype = 'Full-time'
	) AS ot
INNER JOIN wages w
	ON ot.occupation_id = w.occupation_id
GROUP BY ot.occupation
ORDER BY ave_wage DESC;

-- 8. Comparison of work type wage levels by occupation

WITH wage_worktype AS(
SELECT ot.worktype, ot.occupation, AVG(w.ave_weekly_wage) AS ave_wage
FROM (
	SELECT o.occupation_id, o.occupation, w.worktype
	FROM occupations o
	INNER JOIN worktypes w
		ON o.worktype_id = w.worktype_id
	) AS ot
INNER JOIN wages w
	ON ot.occupation_id = w.occupation_id
GROUP BY ot.worktype, ot.occupation
)
SELECT wp.occupation, (wf.ave_wage / wp.ave_wage) AS worktype_wage_ratio
FROM (
	SELECT *
	FROM wage_worktype
	WHERE worktype = 'Full-time'
	) AS wf
INNER JOIN wage_worktype wp
	ON wf.occupation = wp.occupation
WHERE wp.worktype = 'Part-time'
ORDER BY worktype_wage_ratio DESC;

-- 9. Average wage levels by gender in various occupations

SELECT o.occupation, p.sex,
SUM(CASE WHEN w.ave_weekly_wage > 1217 THEN 1 ELSE 0 END) AS high_wage,
SUM(CASE WHEN w.ave_weekly_wage BETWEEN 516 AND 1217 THEN 1 ELSE 0 END) AS medium_wage,
SUM(CASE WHEN w.ave_weekly_wage < 516 THEN 1 ELSE 0 END) AS low_wage
FROM wages w
INNER JOIN profiles p
	ON w.profile_id = p.profile_id
INNER JOIN occupations o
	ON w.occupation_id = o.occupation_id
GROUP BY o.occupation, p.sex
ORDER BY 1, 2 DESC;

-- 10. Observe the wage distribution by occupation in some provinces

WITH pvso AS(
SELECT o.occupation, p.province, 
SUM(CASE WHEN w.ave_weekly_wage > 1217 THEN 1 ELSE 0 END) AS high_wage,
SUM(CASE WHEN w.ave_weekly_wage BETWEEN 516 AND 1217 THEN 1 ELSE 0 END) AS medium_wage,
SUM(CASE WHEN w.ave_weekly_wage < 516 THEN 1 ELSE 0 END) AS low_wage
FROM wages w
INNER JOIN provinces p
	ON w.province_id = p.province_id
INNER JOIN occupations o
	ON w.occupation_id = o.occupation_id
WHERE province IN ('Alberta', 'Ontario')
GROUP BY o.occupation, p.province
)
SELECT occupation, province,
round(high_wage / (high_wage + medium_wage + low_wage)::numeric, 2) AS high_wage_per,
round(medium_wage / (high_wage + medium_wage + low_wage)::numeric, 2) AS medium_wage_per,
round(low_wage / (high_wage + medium_wage + low_wage)::numeric, 2) AS low_wage_per
FROM pvso
ORDER BY occupation, province;

-- View 1. For marketing department

CREATE VIEW marketing_target AS
SELECT pf.sex, pf.age, pv.province, AVG(w.ave_weekly_wage)
FROM wages w
LEFT JOIN profiles pf
	ON w.profile_id = pf.profile_id
LEFT JOIN provinces pv
	ON w.province_id = pv.province_id
GROUP BY pf.sex, pf.age, pv.province
ORDER BY pf.sex, pf.age, pv.province;

-- View 2. For Human Resource department

CREATE VIEW HR_recruitment AS
SELECT y.year, o.occupation, AVG(w.ave_weekly_wage)
FROM wages w
LEFT JOIN years y
	ON w.year_id = y.year_id
LEFT JOIN occupations o
	ON w.occupation_id = o.occupation_id
GROUP BY y.year, o.occupation
ORDER BY y.year, o.occupation;

