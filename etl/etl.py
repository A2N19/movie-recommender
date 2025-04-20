import pandas as pd
from minio import Minio
import psycopg2
import io

# MinIO config
client = Minio("minio:9000", access_key="minioadmin", secret_key="minioadmin", secure=False)
bucket_name = "raw-movies"
file_name = "imdb_top_1000.csv"

# Ensure bucket exists
if not client.bucket_exists(bucket_name):
    client.make_bucket(bucket_name)

# Download file from MinIO
response = client.get_object(bucket_name, file_name)
df = pd.read_csv(io.BytesIO(response.read()))

# Clean data (simple example)
df_clean = df.dropna(subset=["Series_Title", "Genre", "IMDB_Rating"]).copy()
df_clean = df_clean[["Series_Title", "Genre", "IMDB_Rating"]]
df_clean.columns = ["title", "genre", "rating"] 

# Load to PostgreSQL
conn = psycopg2.connect(
    host="postgres",
    port=5432,
    dbname="movies",
    user="user",
    password="password"
)
cursor = conn.cursor()
cursor.execute("""
    CREATE TABLE IF NOT EXISTS movies (
        id SERIAL PRIMARY KEY,
        title TEXT,
        genre TEXT,
        rating FLOAT
    );
""")
conn.commit()

for _, row in df_clean.iterrows():
    cursor.execute("INSERT INTO movies (title, genre, rating) VALUES (%s, %s, %s);", (row["title"], row["genre"], row["rating"]))
conn.commit()
cursor.close()
conn.close()
