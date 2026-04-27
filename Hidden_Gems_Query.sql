/* Cleans table on rerun to ensure that no previous data is in future runs */
Drop TABLE IF EXISTS movie_person;
Drop TABLE IF EXISTS movie_genre;
Drop TABLE IF EXISTS rating;
Drop TABLE IF EXISTS person;
Drop TABLE IF EXISTS genre;
Drop TABLE IF EXISTS movie;
Drop TABLE IF EXISTS imdb_titles_raw;
Drop TABLE IF EXISTS imdb_ratings_raw;
Drop TABLE IF EXISTS imdb_names_raw;
Drop TABLE IF EXISTS imdb_principals_raw;

/* Used to create the main tables, those being movie, rating, genre, and person */
/* Each movie has a unique id, a title, the year it came out, how long the movie was, and a type for the title. */
CREATE TABLE movie (
movie_id TEXT PRIMARY KEY,
title TEXT,
release_year INT,
runtime INT,
title_type TEXT
);
/* Ratings consist of the movie_id to get the infor of the movie, then the average
rating, which is from 1 to 10, can be nums such as 1.8, 2.7, etc. */
CREATE TABLE rating (
movie_id TEXT PRIMARY KEY,
average_rating FLOAT,
num_votes INT,
FOREIGN KEY(movie_id) REFERENCES movie(movie_id)
);
/* Each genre has an id and each genre is unique, there are no two genres with the same name */
CREATE TABLE genre (
genre_id SERIAL PRIMARY KEY,
genre_name TEXT UNIQUE
);
/* Each person in the movie has a unique id, each person has a name and a year they were born */
CREATE TABLE person (
person_id TEXT PRIMARY KEY,
name TEXT,
birth_year INT
);

/* Used for relational tables */

CREATE TABLE movie_genre (
movie_id TEXT,
genre_id INT,
PRIMARY KEY (movie_id, genre_id),
FOREIGN KEY(movie_id) REFERENCES movie(movie_id) ON DELETE CASCADE,
FOREIGN KEY(genre_id) REFERENCES genre(genre_id) ON DELETE CASCADE
);

CREATE TABLE movie_person (
movie_id TEXT,
person_id TEXT,
role TEXT,
PRIMARY KEY (movie_id, person_id),
FOREIGN KEY(movie_id) REFERENCES movie(movie_id) ON DELETE CASCADE,
FOREIGN KEY(person_id) REFERENCES person(person_id) ON DELETE CASCADE
);

/* Tables used to take in the IMDB data */

CREATE TABLE imdb_titles_raw(
tconst TEXT,
titleType TEXT,
primaryTitle TEXT,
originalTitle TEXT, 
isAdult TEXT,
startYear TEXT,
endYear TEXT, 
runtimeMinutes TEXT,
genres TEXT
);

CREATE TABLE imdb_ratings_raw(
tconst TEXT,
averageRating FLOAT,
numVotes INT
);

CREATE TABLE imdb_names_raw(
nconst TEXT,
primaryName TEXT,
birthYear TEXT,
deathYear TEXT, 
primaryProfession TEXT
);

CREATE TABLE imdb_principals_raw(
tconst TEXT, 
ordering INT,
nconst TEXT,
category TEXT,
job TEXT,
characters TEXT
);

/* Used to import raw data from IMDB non-commercial databases*/
COPY imdb_titles_raw
FROM 'C:\Users\Gigis\Downloads\title.basics.tsv.gz '
DELIMITER E'\t'
CSV HEADER;

COPY imdb_ratings_raw
FROM 'C:\Users\Gigis\Downloads\title.ratings.tsv.gz'
DELIMITER E'\t'
CSV HEADER;

COPY imdb_names_raw
FROM 'C:\Users\Gigis\Downloads\name.basics.tsv.gz '
DELIMITER E'\t'
CSV HEADER;

COPY imdb_principals_raw
FROM 'C:\Users\Gigis\Downloads\title.principals.tsv.gz '
DELIMITER E'\t'
CSV HEADER;

/* Inserts data from database into tables */

INSERT INTO movie (movie_id, title, release_year, runtime, title_type)
SELECT
tconst,
primaryTitle,
NULLIF(startYear, '\N')::INT,
NULLIF(runtimeMinutes, '\N')::INT,
titleType
FROM imdb_titles_raw
WHERE titleType IN ('movie', 'tvSeries');

INSERT INTO rating (movie_id, average_rating, num_votes)
SELECT
tconst,
averageRating,
numVotes
FROM imdb_ratings_raw;

INSERT INTO person (person_id, name, birth_year)
Select
nconst,
primaryName,
NULLIF(birthYear, '\N')::INT
FROM imdb_names_raw;

INSERT INTO genre (genre_name)
SELECT DISTINCT unnest(string_to_array(genres, ','))
FROM imdb_titles_raw
WHERE genres IS NOT NULL AND genres<> '\N';

INSERT INTO movie_genre (movie_id, genre_id)
SELECT
t.tconst,
g.genre_id
FROM imdb_titles_raw t
JOIN genre g
ON g.genre_name = ANY(string_to_array(t.genres, ','));

INSERT INTO movie_person(movie_id, person_id, role)
SELECT
tconst,
nconst,
category
FROM imdb_principals_raw;

/* Used to search the query */
SELECT *
FROM movie
WHERE title ILIKE '%love%';

/* Used to join the query */
SELECT m.title, g.genre_name
FROM movie m
JOIN movie_genre mg ON m.movie_id = mg.movie_id
JOIN genre g ON mg.genre_id = g.genre_id
LIMIT 20;

/* Used to aggregate the query */
SELECT g.genre_name, COUNT(*) as total_movies
FROM genre g
JOIN movie_genre mg ON g.genre_id = mg.genre_id
GROUP BY g.genre_name
ORDER BY total_movies DESC;

/* Used for Updating the database */
UPDATE movie
SET runtime = 120
WHERE movie_id = 'xx112233';

/* Used for Deleting from the database */
DELETE FROM movie
WHERE movie_id = 'xx112233';

/* Used for the hidden gem finder part of the application */
SELECT
m.title,
r.average_rating,
r.num_votes,

(r.average_rating / 10.0) AS normalized_ratings,
(1.0 / LOG(r.num_votes + 1)) AS inverse_vote_weight,
(
0.6 * (r.average_rating / 10.0) +
0.4 * (1.0 / LOG(r.num_votes + 1))
) AS hidden_gem_score

FROM movie m
JOIN rating r ON m.movie_id = r.movie_id
ORDER BY hidden_gem_score DESC
LIMIT 20;

