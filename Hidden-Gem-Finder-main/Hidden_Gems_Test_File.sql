SELECT
    m.title,
    r.average_rating,
    r.num_votes,
    (
        0.6 * (r.average_rating / 10.0) +
        0.4 * (1.0 / LOG(r.num_votes + 1))
    ) AS score
FROM movie m
JOIN rating r ON m.movie_id = r.movie_id
ORDER BY score DESC
LIMIT 20;