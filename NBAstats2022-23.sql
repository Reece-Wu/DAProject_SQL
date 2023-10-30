-- 1. The relationship between the five-dimensional indicators and salary of the top 10 players

SELECT player_name, 100 - DENSE_RANK() OVER(ORDER BY pts DESC) AS pts_rank, 100 - DENSE_RANK() OVER(ORDER BY ast DESC) AS ast_rank, 
100 - DENSE_RANK() OVER(ORDER BY trb DESC) AS trb_rank, 100 - DENSE_RANK() OVER(ORDER BY stl DESC) AS stl_rank, 100 - DENSE_RANK() OVER(ORDER BY blk DESC) AS blk_rank
FROM nba_stats
WHERE (CAST(gs AS numeric)/gp) > 0.8 AND gp > 41 AND  mp > 30
ORDER BY salary DESC
LIMIT 10



-- 2. The Relationship Between Playing Position on the Court and Salary

SELECT *
FROM (
	SELECT 
		CASE WHEN positions IN ('SG-PG', 'PG-SG', 'SG', 'PG') THEN 'Guard'
			 WHEN positions IN ('SF-PF', 'SF', 'PF') THEN 'Forward'
			 WHEN positions IN ('C') THEN 'Center'
		 	 ELSE positions
		END AS cat_position,
		ROUND(AVG(salary), 1) AS average,
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median
	FROM nba_stats
	GROUP BY cat_position
	) AS cat_position
WHERE cat_position <> 'SF-SG' -- Ignore 2 data spanning different positions
ORDER BY average DESC



-- 3. Calculate the total salary of each team

SELECT SUM(salary) AS team_salary,
	CASE WHEN team LIKE '%/%' THEN SUBSTRING(team FROM POSITION('/' IN team) + 1)
		 ELSE team
	END AS current_team,
	longitude, latitude
FROM nba_stats
GROUP BY current_team, longitude, latitude
ORDER BY team_salary DESC

   -- Add column

ALTER TABLE nba_stats
ADD longitude NUMERIC;
ALTER TABLE nba_stats
ADD latitude NUMERIC;

WITH cte AS(
	SELECT player_name,
	CASE WHEN team LIKE '%/%' THEN SUBSTRING(team FROM POSITION('/' IN team) + 1)
		 ELSE team
	END AS new_team
FROM nba_stats
)
UPDATE nba_stats
SET longitude = 
	CASE WHEN new_team = 'ATL' THEN -84.396190
		 WHEN new_team = 'BOS' THEN -71.062141
		 WHEN new_team = 'BRK' THEN -73.975372
		 WHEN new_team = 'CHO' THEN -80.839370
		 WHEN new_team = 'CHI' THEN -87.674391
		 WHEN new_team = 'CLE' THEN -81.688120
		 WHEN new_team = 'DAL' THEN -96.810177
		 WHEN new_team = 'DEN' THEN -105.007461
		 WHEN new_team = 'DET' THEN -83.055171
		 WHEN new_team = 'GSW' THEN -122.386651
		 WHEN new_team = 'HOU' THEN -95.362875
		 WHEN new_team = 'IND' THEN -86.155207
		 WHEN new_team = 'LAC' THEN -118.267037
		 WHEN new_team = 'LAL' THEN -118.267037
		 WHEN new_team = 'MEM' THEN -90.050369
		 WHEN new_team = 'MIA' THEN -80.187241
		 WHEN new_team = 'MIL' THEN -87.916653
		 WHEN new_team = 'MIN' THEN -93.276758
		 WHEN new_team = 'NOP' THEN -90.081493
		 WHEN new_team = 'NYK' THEN -73.993573
		 WHEN new_team = 'OKC' THEN -97.515881
		 WHEN new_team = 'ORL' THEN -81.383949
		 WHEN new_team = 'PHI' THEN -75.171312
		 WHEN new_team = 'PHO' THEN -112.071747
		 WHEN new_team = 'POR' THEN -122.667580
		 WHEN new_team = 'SAC' THEN -121.500072
		 WHEN new_team = 'SAS' THEN -98.437484
		 WHEN new_team = 'TOR' THEN -79.379767
		 WHEN new_team = 'UTA' THEN -111.901169
		 WHEN new_team = 'WAS' THEN -77.021908
		 ELSE NULL
	END,
	latitude = 
	CASE WHEN new_team = 'ATL' THEN 33.757289
		 WHEN new_team = 'BOS' THEN 42.366303
		 WHEN new_team = 'BRK' THEN 40.682656
		 WHEN new_team = 'CHO' THEN 35.225126
		 WHEN new_team = 'CHI' THEN 41.880685
		 WHEN new_team = 'CLE' THEN 41.496480
		 WHEN new_team = 'DAL' THEN 32.790351
		 WHEN new_team = 'DEN' THEN 39.748697
		 WHEN new_team = 'DET' THEN 42.342536
		 WHEN new_team = 'GSW' THEN 37.768056
		 WHEN new_team = 'HOU' THEN 29.750345
		 WHEN new_team = 'IND' THEN 39.763976
		 WHEN new_team = 'LAC' THEN 34.043017
		 WHEN new_team = 'LAL' THEN 34.043017
		 WHEN new_team = 'MEM' THEN 35.138046
		 WHEN new_team = 'MIA' THEN 25.781801
		 WHEN new_team = 'MIL' THEN 43.044808
		 WHEN new_team = 'MIN' THEN 44.979363
		 WHEN new_team = 'NOP' THEN 29.949365
		 WHEN new_team = 'NYK' THEN 40.750509
		 WHEN new_team = 'OKC' THEN 35.463368
		 WHEN new_team = 'ORL' THEN 28.539860
		 WHEN new_team = 'PHI' THEN 39.901286
		 WHEN new_team = 'PHO' THEN 33.445768
		 WHEN new_team = 'POR' THEN 45.531692
		 WHEN new_team = 'SAC' THEN 38.580131
		 WHEN new_team = 'SAS' THEN 29.426231
		 WHEN new_team = 'TOR' THEN 43.643464
		 WHEN new_team = 'UTA' THEN 40.768303
		 WHEN new_team = 'WAS' THEN 38.898208
		 ELSE NULL
	END
FROM cte
WHERE nba_stats.player_name = cte.player_name;



-- 4. The relationship between age, playing time and salary

SELECT
	CASE WHEN age BETWEEN 19 AND 24 THEN '19-24'
		 WHEN age BETWEEN 25 AND 30 THEN '25-30'
		 WHEN age BETWEEN 31 AND 36 THEN '31-36'
		 WHEN age BETWEEN 37 AND 42 THEN '37-42'
		 ELSE NULL
	END AS age_category,
	ROUND(AVG(mp::numeric), 1) AS ave_minutes_played, CAST(AVG(salary) AS INTEGER) AS ave_salary, PERCENTILE_CONT(0.5) WITHIN GROUP(ORDER BY salary) AS med_salary
FROM nba_stats
GROUP BY age_category
ORDER BY age_category



-- 5. Use the 3 most comprehensive metrics: PER, WS and VORP to understand the relationship between performance and salary

WITH ranked_players AS(
	SELECT player_name, RANK() OVER (ORDER BY salary DESC) AS salary_rank, per, ws, vorp
	FROM nba_stats
)
SELECT player_name, salary_rank, per_score, ws_score, vorp_score, (per_score + ws_score + vorp_score) AS total_score
FROM(
	SELECT player_name, salary_rank,
		CASE WHEN per >= (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY per) FROM ranked_players) THEN 5
		 	WHEN per >= (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY per) FROM ranked_players) 
				AND per < (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY per) FROM ranked_players) THEN 4
			WHEN per >= (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY per) FROM ranked_players) 
				AND per < (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY per) FROM ranked_players) THEN 3
			WHEN per >= (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY per) FROM ranked_players) 
				AND per < (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY per) FROM ranked_players) THEN 2
		 	WHEN per < (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY per) FROM ranked_players) THEN 1
		 	ELSE NULL
		END AS per_score,
		CASE WHEN ws >= (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY ws) FROM ranked_players) THEN 5
		 	WHEN ws >= (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY ws) FROM ranked_players) 
				AND ws < (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY ws) FROM ranked_players) THEN 4
			WHEN ws >= (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY ws) FROM ranked_players) 
				AND ws < (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY ws) FROM ranked_players) THEN 3
			WHEN ws >= (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY ws) FROM ranked_players) 
				AND ws < (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY ws) FROM ranked_players) THEN 2
		 	WHEN ws < (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY ws) FROM ranked_players) THEN 1
		 	ELSE NULL
		END AS ws_score,
		CASE WHEN vorp >= (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) THEN 5
		 	WHEN vorp >= (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) 
				AND vorp < (SELECT PERCENTILE_CONT(0.8) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) THEN 4
			WHEN vorp >= (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) 
				AND vorp < (SELECT PERCENTILE_CONT(0.6) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) THEN 3
			WHEN vorp >= (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) 
				AND vorp < (SELECT PERCENTILE_CONT(0.4) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) THEN 2
		 	WHEN vorp < (SELECT PERCENTILE_CONT(0.2) WITHIN GROUP(ORDER BY vorp) FROM ranked_players) THEN 1
		 	ELSE NULL
		END AS vorp_score
	FROM ranked_players
) AS scored_players
ORDER BY salary_rank, total_score DESC



-- Create Table

CREATE TABLE nba_stats(
	player_name CHARACTER VARYING(30),
	salary INTEGER,
	positions CHARACTER VARYING(10),
	age INTEGER,
	team CHARACTER VARYING(10),
	gp INTEGER,
	gs INTEGER,
	mp DOUBLE PRECISION,
	fg DOUBLE PRECISION,
	fga DOUBLE PRECISION,
	fg_per DOUBLE PRECISION,
	_3p DOUBLE PRECISION,
	_3pa DOUBLE PRECISION,
	_3p_per DOUBLE PRECISION,
	_2p DOUBLE PRECISION,
	_2pa DOUBLE PRECISION,
	_2p_per DOUBLE PRECISION,
	efg_per DOUBLE PRECISION,
	ft DOUBLE PRECISION,
	fta DOUBLE PRECISION,
	ft_per DOUBLE PRECISION,
	orb DOUBLE PRECISION,
	drb DOUBLE PRECISION,
	trb DOUBLE PRECISION,
	ast DOUBLE PRECISION,
	stl DOUBLE PRECISION,
	blk DOUBLE PRECISION,
	tov DOUBLE PRECISION,
	pf DOUBLE PRECISION,
	pts DOUBLE PRECISION,
	Total_minute INTEGER,
	per DOUBLE PRECISION,
	ts_per DOUBLE PRECISION,
	_3par DOUBLE PRECISION,
	ftr DOUBLE PRECISION,
	orb_per DOUBLE PRECISION,
	drb_per DOUBLE PRECISION,
	trb_per DOUBLE PRECISION,
	ast_per DOUBLE PRECISION,
	stl_per DOUBLE PRECISION,
	blk_per DOUBLE PRECISION,
	tov_per DOUBLE PRECISION,
	usg_per DOUBLE PRECISION,
	ows DOUBLE PRECISION,
	dws DOUBLE PRECISION,
	ws DOUBLE PRECISION,
	ws48 DOUBLE PRECISION,
	obpm DOUBLE PRECISION,
	dbpm DOUBLE PRECISION,
	bpm DOUBLE PRECISION,
	vorp DOUBLE PRECISION
)
