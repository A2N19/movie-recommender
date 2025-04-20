from flask import Flask, jsonify, request
from flask_cors import CORS
import psycopg2
import pandas as pd

app = Flask(__name__)
CORS(app)

@app.route("/recommendations")
def recommend():
    genre = request.args.get("genre")
    min_rating = request.args.get("rating", default=0, type=float)

    conn = psycopg2.connect(
        host="postgres",
        port=5432,
        dbname="movies",
        user="user",
        password="password"
    )

    query = "SELECT DISTINCT title, genre, rating FROM movies WHERE rating >= %s"
    params = [min_rating]

    if genre:
        query += " AND genre ILIKE %s"
        params.append(f"%{genre}%")

    query += " ORDER BY rating DESC"
    df = pd.read_sql(query, conn, params=params)

    conn.close()
    return jsonify(df.to_dict(orient="records"))

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
