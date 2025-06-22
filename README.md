# relevant-document-retrieval

> **One‑liner:** A lightweight, self‑hosted RAG layer that turns *natural‑language prompts* into **precise document hits** using local, pretrained embedding models and classic lexical search.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Architecture](#architecture)
4. [Quick Start](#quick-start)
5. [Models](#models)
6. [Directory & File Reference](#directory--file-reference)
7. [Configuration](#configuration)
8. [Testing & Linting](#testing--linting)
9. [Benchmarking](#benchmarking)
10. [Deployment](#deployment)
11. [Contributing](#contributing)
12. [Roadmap](#roadmap)
13. [License](#license)
14. [Authors & Acknowledgements](#authors--acknowledgements)
15. [FAQ / Troubleshooting](#faq--troubleshooting)

---

## Project Overview

Modern LLM agents excel at *reasoning* but still struggle with *factual recall* beyond their training cut‑off. **relevant‑document‑retrieval** fixes this by adding a retrieval‑augmented generation (RAG) layer: it ingests arbitrary files (PDF, Markdown, HTML, etc.), creates dense vector embeddings plus BM25 indices, and exposes API & CLI endpoints that return the *most relevant* chunks for a given question.

Key design goals:

* **Local‑first.** No cloud keys, no external calls — everything runs on your machine or server.
* **Hackathon‑friendly.** `make docker-up`, drop docs into *samples/*, query. That’s it.
* **Composable.** Clear extension points for new chunkers, parsers, and embedding back‑ends.

---

## Key Features

* 🔍 **Hybrid Search:** dense vectors (`pgvector`) + [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) scoring for high recall & precision.
* ✂️ **MMR Chunking:** on‑the‑fly [Maximal Marginal Relevance](https://huggingface.co/docs/transformers/main/en/main_classes/retriever#maximal-marginal-relevance) reduces redundancy while preserving coverage.
* ⚡ **Streaming API:** Server‑Sent Events (SSE) let front‑ends display retrieval hits in real time.
* 🧩 **Retrieval‑QA Chain:** ready‑to‑use LangChain `RetrievalQA` wrapper to feed results directly into any LLM.
* 🤝 **Pretrained, Offline Models:** ships with `sentence-transformers/all-MiniLM-L6-v2` (open licence, 384‑dim vectors) — no external API keys.
* 🐳 **One‑command boot‑up:** `make docker-up` spins Postgres 15 + pgvector 0.7 and the FastAPI service.

---

## Architecture

```text
┌────────────┐    ingest        ┌──────────────┐
│   Files    │ ───────────────▶│   Ingestor   │
└────────────┘                  └─────┬────────┘
                                      │ chunks + embeddings
                           ┌──────────▼───────────┐
                           │   Postgres + pgvector│
                           └──────────▲───────────┘
                                      │ top‑k vectors
┌───────────────┐  query   ┌──────────┴───────────┐
│ REST / CLI /  │─────────▶│ Retrieval Service    │
│   LangChain   │          └──────────┬───────────┘
└───────────────┘                     │ docs
                           ┌──────────┴───────────┐
                           │  Retrieval‑QA Chain  │
                           └──────────┬───────────┘
                                      ▼
                            ┌──────────┴─────────┐
                            │  Down‑stream LLM   │
                            └────────────────────┘

```                         

### Components

| Piece                  | Role                                                            |
| ---------------------- | --------------------------------------------------------------- |
| **FastAPI** gateway    | Exposes `/ingest` and `/query` endpoints (SSE‑capable).         |
| **Ingestor workers**   | Extract text (PDFMiner, BeautifulSoup), split, embed.           |
| **Vector store**       | Postgres 15 + [pgvector](https://github.com/pgvector/pgvector). |
| **Retrieval‑QA Chain** | LangChain wrapper that combines retriever + LLM.                |
| **Embedding model**    | `sentence-transformers/all-MiniLM-L6-v2` (local).               |

---

## Quick Start

### Prerequisites

* **Python ≥ 3.11** (for CLI; the main service runs in Docker)
* **Docker ≥ 24.0** and **docker‑compose v2**
* CPU is enough for small demos; GPU (CUDA 11+) speeds up embeddings.

### Local Setup

```bash
git clone https://github.com/your-org/relevant-document-retrieval.git
cd relevant-document-retrieval

python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Copy and edit env vars
cp .env.example .env
```

### Running with Docker Compose

```bash
# 1) Start Postgres + pgvector + API
docker compose up -d --build   # or: make docker-up

# 2) Ingest sample docs
rel-doc ingest ./samples

# 3) Query
rel-doc query "Что такое когерентность волн?"
```

### Makefile goodies

| Command            | Action                             |
| ------------------ | ---------------------------------- |
| `make docker-up`   | Build & start all containers       |
| `make docker-down` | Stop + remove containers & volumes |
| `make fmt`         | Run *ruff* + isort                 |
| `make test`        | Run unit tests inside tox          |

---

## Models

| Model                                    | Dim | License    | Notes                                       |
| ---------------------------------------- | --- | ---------- | ------------------------------------------- |
| `sentence-transformers/all-MiniLM-L6-v2` | 384 | Apache‑2.0 | Default embedder; <50 MB.                   |
| *Bring your own*                         | —   | —          | Any model accepted by LangChain Embeddings. |

> **No datasets included.** The system indexes whatever files you drop into *samples/* or pass to the ingest API.

---

## Directory & File Reference

<details>
<summary>First‑level tree</summary>

```text
./
├── __pycache__/
├── __run_once_flags__/
├── database/
├── document_load_pipe.py
├── init_stat.txt
├── llm/
├── main.py
├── metadata_structure.md
├── models/
├── parsers/
├── requirements.txt
├── tempCodeRunnerFile.py
├── test/
└── utils/
```

</details>

| Path                                               | Purpose                                  | Key tech / notes                                                                   |
| -------------------------------------------------- | ---------------------------------------- | ---------------------------------------------------------------------------------- |
| [`main.py`](./main.py)                             | FastAPI app entrypoint                   | [`FastAPI`](https://fastapi.tiangolo.com/) · [`uvicorn`](https://www.uvicorn.org/) |
| [`document_load_pipe.py`](./document_load_pipe.py) | CLI for batch ingestion                  | [`click`](https://click.palletsprojects.com/)                                      |
| [`llm/`](./llm/)                                   | Provider adapters (HF, local)            | LangChain wrappers                                                                 |
| [`models/`](./models/)                             | Pydantic DTOs / ORM models               | [`SQLModel`](https://sqlmodel.tiangolo.com/)                                       |
| [`parsers/`](./parsers/)                           | File‑type handlers (PDF, HTML, Markdown) | PDFMiner, BeautifulSoup                                                            |
| [`utils/`](./utils/)                               | Common helpers (chunking, hashing)       | pure Python                                                                        |
| [`database/`](./database/)                         | SQL migrations, seeds                    | Alembic scripts                                                                    |
| [`test/`](./test/)                                 | Pytest suites & fixtures                 | [`pytest`](https://docs.pytest.org/)                                               |

---

## Configuration

| Variable            | Default                                  | Description                                      |
| ------------------- | ---------------------------------------- | ------------------------------------------------ |
| `POSTGRES_HOST`     | `localhost`                              | DB endpoint                                      |
| `POSTGRES_PORT`     | `5432`                                   | —                                                |
| `POSTGRES_USER`     | `postgres`                               | —                                                |
| `POSTGRES_PASSWORD` | `postgres`                               | —                                                |
| `EMBEDDING_MODEL`   | `sentence-transformers/all-MiniLM-L6-v2` | Any embedding model string accepted by LangChain |
| `CHUNK_SIZE`        | `512`                                    | Tokens per chunk                                 |
| `MMR_K`             | `20`                                     | Window size for MMR selection                    |
| `TOP_K`             | `5`                                      | Retrieval depth                                  |

Create your own `.env` or pass vars via `docker compose --env-file`.

---

## Testing & Linting

```bash
pytest -q        # unit & integration
ruff check .     # static analysis
ruff format .    # auto‑format
```

Pre‑commit hooks live in `.pre-commit-config.yaml`; run `pre-commit install` after cloning.

---

## Benchmarking

| Metric                       | Script                    | Notes                 |
| ---------------------------- | ------------------------- | --------------------- |
| Ingest throughput (docs/sec) | `scripts/bench_ingest.py` | CPU i7‑12700H         |
| Query latency (P99)          | `scripts/bench_query.py`  | 100 parallel requests |

CSV outputs live in `bench/` and can be plotted with `python scripts/plot.py`.

---

## Deployment

| Target             | Hint                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------ |
| **Docker Compose** | `docker compose -f deploy/prod.yml up -d --scale api=3`                              |
| **Kubernetes**     | See `charts/reldoc/values.yaml` for resources & autoscaling                          |
| **HF Spaces**      | Comment out Postgres, switch to `sqlite+aiosqlite://`                                |
| **GPU box**        | Mount `--gpus all` and set `EMBEDDING_MODEL=sentence-transformers/all-mpnet-base-v2` |

Tune `shared_buffers` & `work_mem` in `postgresql.conf` for large corpora.

---

## Contributing

We follow **[Conventional Commits](https://www.conventionalcommits.org/)** + GitHub Flow.

1. `feat/my-brief-topic` branch off **main**
2. `make fmt && make test` must pass
3. Open PR, request review from `@team-Budapest/owners`

All code changes require matching unit tests.

---

## Roadmap

* [ ] PDF table extraction
* [ ] Vector‑aware summarization endpoint
* [ ] Web UI (React + [Intersection Observer](https://developer.mozilla.org/docs/Web/API/Intersection_Observer) for infinite scroll)
* [ ] Model hot‑swap via OCI image
* [ ] Bench suite on A100 vs CPU

---

## License

This project is licensed under the **Apache-2.0** License – see [LICENSE](./LICENSE) for details.

---

## Authors & Acknowledgements

Developed with ☕ by **Команда «Будапешт»**.
Big thanks to the OSS community behind FastAPI, pgvector, SentenceTransformers, and LangChain.

---

## FAQ / Troubleshooting

| Question                                                     | Fix                                                                                 |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| **`psycopg2.OperationalError: could not connect to server`** | Ensure `docker compose ps` shows the `db` container healthy; check `POSTGRES_HOST`. |
| **`pgvector extension "vector" does not exist`**             | Run `CREATE EXTENSION IF NOT EXISTS vector;` or rebuild with `make docker-up`.      |
| CUDA‑enabled embedder OOM                                    | Lower `BATCH_SIZE` or switch to CPU model.                                          |
| Tokenizer mismatch error                                     | Delete `vector_cache/`, re-ingest with consistent model/version.                    |
| CORS blocked in browser                                      | Set `ALLOWED_ORIGINS=*` (dev) or whitelist domains.                                 |
| UnicodeDecodeError on ingest                                 | Add `--encoding utf-8` flag or update `parsers/file_loader.py`.                     |
| CLI hangs on Windows                                         | Use `winpty rel-doc ...` (Git Bash) or WSL.                                         |
| Inaccurate search results                                    | Increase \`CH                                                                       |
