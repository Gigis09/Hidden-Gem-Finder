# addons used for better handling of the api 
 from flask import FLASK, request, jsonify
 import psycopg2
 from flask_cors import CORS

 app = Flask()
 Cors(app)

# Used to connect to the postgre server
 conn = psycopg2.connect(
    dbname="hidden_gems_db",
    user="postgres",
    password="yourpassword",
    host="localhost",
    port="5432"

# Used to search for movies, 
 @app.route('/movies/search')
 def search_movies():
    title = request.args.get('title', '')

    cur = conn.cursor()
    cur.execute("""
        SELECT m.title, m.release_year, r.average_rating, r.num_votes
        FROM movie m
        LEFT JOIN rating r ON m.movie_id = r.movie_id
        WHERE m.title ILIKE %s
        LIMIT 20
    """, (f"%{title}%",))

    rows = cur.fetchall()
    cur.close()

    return jsonify(rows)
# Used to insert a movie into the database
   @app.route('/movies', methods=['POST'])
   def add_movie():
    data = request.json

    cur = conn.cursor()
    cur.execute("""
        INSERT INTO movie (movie_id, title, release_year, runtime, title_type)
        VALUES (%s, %s, %s, %s, %s)
    """, (
        data['movie_id'],
        data['title'],
        data['release_year'],
        data['runtime'],
        data['title_type']
    ))

    conn.commit()
    cur.close()

    return jsonify({"message": "Movie added"})

# Used to update a movie runtime
    @app.route('/movies/<movie_id>', methods=['PUT'])
    def update_movie(movie_id):
    runtime = request.json.get('runtime')

    cur = conn.cursor()
    cur.execute("""
        UPDATE movie SET runtime = %s WHERE movie_id = %s
    """, (runtime, movie_id))

    conn.commit()
    cur.close()

    return jsonify({"message": "Updated"})

 # Used to remove a movie from the database
    @app.route('/movies/<movie_id>', methods=['DELETE'])
    def delete_movie(movie_id):
    cur = conn.cursor()
    cur.execute("DELETE FROM movie WHERE movie_id = %s", (movie_id,))
    conn.commit()
    cur.close()

    return jsonify({"message": "Deleted"})

# Used to create a join query or combine movies and genres
  @app.route('/movies/genres')
  def movies_genres():
    cur = conn.cursor()
    cur.execute("""
        SELECT m.title, g.genre_name
        FROM movie m
        JOIN movie_genre mg ON m.movie_id = mg.movie_id
        JOIN genre g ON mg.genre_id = g.genre_id
        LIMIT 20
    """)
    rows = cur.fetchall()
    cur.close()

    return jsonify(rows)

# Used to create an aggregation query which counts the amount of movies per genre
  @app.route('/genres/count')
  def genre_count():
    cur = conn.cursor()
    cur.execute("""
        SELECT g.genre_name, COUNT(*)
        FROM genre g
        JOIN movie_genre mg ON g.genre_id = mg.genre_id
        GROUP BY g.genre_name
        ORDER BY COUNT(*) DESC
        LIMIT 10
    """)
    rows = cur.fetchall()
    cur.close()

    return jsonify(rows)

# Used for the hiddent gem feature 
  @app.route('/hidden-gems')
  def hidden_gems():
    cur = conn.cursor()
    cur.execute("""
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
        LIMIT 20
    """)
    rows = cur.fetchall()
    cur.close()

    return jsonify(rows)

# Used to run the server
  if __name__ == '__main__':
    app.run(debug=True)
