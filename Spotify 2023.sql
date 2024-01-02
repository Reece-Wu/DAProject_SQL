-- Dataset: https://www.kaggle.com/datasets/tonygordonjr/spotify-dataset-2023/
SET search_path TO spotify2023;


-- 1. Track length changes over decade.
-- Question: As the pace of life gets faster and faster with every generation, are track times also getting shorter?
-- Conclusion: There has been a slight decline in average track length over the last fifty years, but only slightly.

SELECT 
	CASE
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '188' THEN '1880s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '189' THEN '1890s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '190' THEN '1900s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '191' THEN '1910s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '192' THEN '1920s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '193' THEN '1930s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '194' THEN '1940s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '195' THEN '1950s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '196' THEN '1960s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '197' THEN '1970s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '198' THEN '1980s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '199' THEN '1990s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '200' THEN '2000s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '201' THEN '2010s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '202' THEN '2020s'
		ELSE 'Unknown'
	END AS release_decade, 
	ROUND(AVG(duration_sec)) AS avg_track_length
FROM spotify2023
WHERE duration_sec IS NOT NULL
	AND release_date IS NOT NULL
GROUP BY release_decade
ORDER BY release_decade DESC


-- 2. Most positive and negative energy songs in every decade(The track popularity must reach 60 points or above).
-- Question: What are the famous positive/negative tracks from each decade?
-- Conclusion: Check out these tracks when you want to listen to happy or sad music.

WITH CTE AS(
SELECT
	CASE
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '188' THEN '1880s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '189' THEN '1890s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '190' THEN '1900s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '191' THEN '1910s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '192' THEN '1920s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '193' THEN '1930s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '194' THEN '1940s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '195' THEN '1950s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '196' THEN '1960s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '197' THEN '1970s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '198' THEN '1980s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '199' THEN '1990s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '200' THEN '2000s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '201' THEN '2010s'
		WHEN LEFT(CAST(EXTRACT(YEAR FROM release_date) AS VARCHAR), 3) = '202' THEN '2020s'
		ELSE 'Unknown'
	END AS release_decade, 
	track_popularity, track_name, artist_0 AS main_artist, valence
FROM spotify2023
WHERE track_popularity BETWEEN 60 AND 99
	AND release_date IS NOT NULL
	AND track_name IS NOT NULL
	AND artist_0 IS NOT NULL
	AND valence IS NOT NULL
)
SELECT release_decade,
	CASE WHEN valence = max_valence THEN 'positive'
		 WHEN valence = min_valence THEN 'negative'
		 ELSE 'NA'
	END AS musical_positiveness, track_name, main_artist
FROM(
	SELECT release_decade, track_name, main_artist, valence,
		MAX(valence) OVER (PARTITION BY release_decade) AS max_valence, 
		MIN(valence) OVER (PARTITION BY release_decade) AS min_valence
	FROM CTE
) AS SUB
WHERE valence = max_valence
	OR valence = min_valence
ORDER BY release_decade DESC, musical_positiveness DESC


-- 3. Distribution of musical tempo levels (BPM).
-- Question: Does the overall track tempo (BPM) distribution tend to be fast or slow?
-- Conclusion: There is a normal distribution tendency, which means that people have the highest acceptance of normal rhythm tracks.

SELECT WIDTH_BUCKET(tempo, min_tempo, max_tempo + 1, 10) AS tempo_bucket, COUNT(tempo) AS num_of_track
FROM spotify2023, (SELECT MIN(tempo) AS min_tempo, MAX(tempo) AS max_tempo FROM spotify2023) AS tempo_limit
WHERE tempo IS NOT NULL
GROUP BY tempo_bucket
ORDER BY tempo_bucket DESC


-- 4. The percentage of the music contains explicit content.
-- Question: Do the tracks often contain explicit content?
-- Conclusion: Only about 15%, most of the tracks are suitable for all ages.

SELECT explicit, num_of_track, ROUND((num_of_track / SUM(num_of_track) OVER ()) * 100, 1) AS track_percentage
FROM(
	SELECT explicit, COUNT(explicit) AS num_of_track
	FROM spotify2023
	WHERE explicit IS NOT NULL
	GROUP BY explicit
) AS SUB


-- 5. Correlation between various indicators and track popularity
-- Question: What track metrics affect track popularity?
-- Conclusion: The most obvious one is "Instrumentalness". When the music doesn't contain vocals, the popularity is generally lower.

SELECT track_popularity, ROUND(AVG(danceability), 2) AS avg_danceability, 
	ROUND(AVG(energy), 2) AS avg_energy, ROUND(AVG(instrumentalness), 2) AS avg_instrumentalness, 
	 ROUND(AVG(mode), 2) AS avg_mode, ROUND(AVG(valence), 2) AS avg_valence
FROM spotify2023
WHERE danceability IS NOT NULL
    AND energy IS NOT NULL
    AND instrumentalness IS NOT NULL
    AND mode IS NOT NULL
    AND valence IS NOT NULL
    AND track_popularity IS NOT NULL
GROUP BY track_popularity

