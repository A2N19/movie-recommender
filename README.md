# 🎬 Movie Recommender System

A full-stack movie recommendation system built using:

- 🐳 Docker & Docker Compose
- 🧺 MinIO (Data Lake)
- 🐘 PostgreSQL (Data Warehouse)
- 🔄 Python ETL
- 🌐 Flask API
- 🖥️ HTML/JS Frontend with filters

---

## ⚙️ Features

- Upload raw movie data to MinIO
- ETL job processes and loads clean data into PostgreSQL
- Flask API serves recommendations
- Frontend allows users to filter by genre and minimum rating

---

## 🧱 Project Structure

```
.
├── backend/           # Flask API
│   ├── app.py
│   └── Dockerfile
├── etl/               # ETL pipeline
│   ├── etl.py
│   └── Dockerfile
├── frontend/          # HTML UI
│   ├── index.html
│   └── Dockerfile
├── data/              # Raw movie CSV
│   └── imdb_top_1000.csv
├── docker-compose.yml
└── README.md
```

---

## 🚀 How to Run

### 1. Clone the repo

```bash
git clone https://github.com/your-username/movie-recommender.git
cd movie-recommender
```

### 2. Start all containers

```bash
docker-compose up --build
```

This will launch:

- `MinIO` on [http://localhost:9001](http://localhost:9001)  
  Login: `minioadmin` / `minioadmin`
- `PostgreSQL` on port `5432`
- `Flask API` on [http://localhost:5000/recommendations](http://localhost:5000/recommendations)
- `Frontend` on [http://localhost:3000](http://localhost:3000)

---

### 3. Upload Data to MinIO

1. Go to [http://localhost:9001](http://localhost:9001)
2. Login: `minioadmin` / `minioadmin`
3. Create a bucket named `raw-movies`
4. Upload the file `data/imdb_top_1000.csv` to that bucket

---

### 4. Run ETL Script

This will process the CSV from MinIO and insert cleaned data into PostgreSQL:

```bash
docker-compose run etl
```

---

## 🧪 Filters Available

The frontend allows filtering by:

- Genre (e.g. `"Drama"`, `"Action"`)
- Minimum Rating (e.g. `8.5`)

---

## 💡 Author

Built with ❤️ by [Your Name]

---

## 📜 License

MIT – feel free to use and modify!
