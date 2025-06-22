# relevant-document-retrieval

> **One-liner:** A lightweight pipeline that turns *natural-language prompts* into **precise document hits** by combining semantic embeddings with classic lexical search.

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Key Features](#key-features)
3. [Demo / Screenshots / Badges](#demo--screenshots--badges)
4. [Architecture](#architecture)
5. [Quick Start](#quick-start)
6. [Datasets & Models](#datasets--models)
7. [Directory & File Reference](#directory--file-reference)
8. [Configuration](#configuration)
9. [Testing & Linting](#testing--linting)
10. [Benchmarking](#benchmarking)
11. [Deployment](#deployment)
12. [Contributing](#contributing)
13. [Roadmap](#roadmap)
14. [License](#license)
15. [Authors & Acknowledgements](#authors--acknowledgements)
16. [FAQ / Troubleshooting](#faq--troubleshooting)

---

## Project Overview

Modern LLM applications excel at *reasoning* but still struggle with *factual recall* beyond their training cut-off. **relevant-document-retrieval** solves this pain by providing a retrieval-augmented generation (RAG) layer: it ingests arbitrary files (PDF, Markdown, HTML, etc.), creates dense vector embeddings plus BM25 indices, and lets you hit an HTTP or CLI endpoint to pull the *most relevant* chunks for a given question.

The goal is to give hackathon teams an “instant memory” for their LLM agents. Instead of hard-coding context windows or manually searching SharePoint, developers can spin up the stack with **one Make command**, drop their docs into the *samples/* folder, and immediately start querying in natural language. The project favors minimal dependencies, Docker-first UX, and clear extensibility points.

---

## Key Features

* 🔍 **Hybrid Search:** dense vectors (`pgvector`) + [BM25](https://en.wikipedia.org/wiki/Okapi_BM25) scoring for high recall & precision.
* ✂️ **MMR Chunking:** on-the-fly [Maximal Marginal Relevance](https://huggingface.co/docs/transformers/main/en/main_classes/retriever#maximal-marginal-relevance) reduces redundancy while preserving coverage.
* ⚡ **Streaming API:** Server-Sent Events (SSE) let front-ends show retrieval hits in real time.
* 📦 **Batteries-included CLI:** `rel-doc ingest` & `rel-doc query` wrap the HTTP calls for quick shell testing.
* 🐳 **One-command boot-up:** `make docker-up` spins Postgres 15 + pgvector 0.7 and the FastAPI service.
* 🧩 **Pluggable Embedders:** swap OpenAI, Hugging Face or local [SentenceTransformers](https://www.sbert.net/) via a single env var.

---

## Demo / Screenshots / Badges

<!--
![demo](docs/demo.gif)

[![CI](https://github.com/org/repo/actions/workflows/ci.yml/badge.svg)](./.github/workflows/ci.yml)
-->

*No public demo yet – add a GIF or Hugging Face Spaces link here when ready.*

---

## Architecture

High-level data-flow:

```text
┌────────────┐    ingest        ┌──────────────┐
│   Files     │ ───────────────▶│   Ingestor    │
└────────────┘                  └─────┬────────┘
                                      │ chunks + embeddings
                           ┌──────────▼───────────┐
                           │   Postgres + pgvector│
                           └──────────▲───────────┘
                                      │ top-k vectors
┌───────────────┐  query   ┌──────────┴───────────┐
│   REST / CLI  │─────────▶│  Retrieval Service   │
└───────────────┘          └──────────┬───────────┘
                                      │ docs
                              (optional) RAG
                                      ▼
                                 Down-stream LLM
```

Components

| Piece                | Role                                                           |
| -------------------- | -------------------------------------------------------------- |
| **FastAPI** gateway  | Exposes `/ingest` and `/query` endpoints (SSE-capable)         |
| **Ingestor workers** | Extract text (PDFMiner, BeautifulSoup), split, embed           |
| **Vector store**     | Postgres 15 + [pgvector](https://github.com/pgvector/pgvector) |
| **LLM provider**     | OpenAI (`text-embedding-3-small`) by default, swappable        |

---

## Quick Start

### Prerequisites

* **Python ≥ 3.11** (only for CLI; the main service runs in Docker)
* **Docker ≥ 24.0** and **docker-compose ≥ v2**
* CPU is enough for small demos; GPU (CUDA 11+) recommended for local embedding models.

### Local Setup

```bash
git clone https://github.com/your-org/relevant-document-retrieval.git
cd relevant-document-retrieval

python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# Copy and fill env vars
cp .env.example .env
```

### Running with Docker Compose

```bash
# 1) Spin up Postgres (with pgvector) and the API
make docker-up           # or: docker-compose up -d

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

## Datasets & Models

| Item                 | Details                                                                   |
| -------------------- | ------------------------------------------------------------------------- |
| **Sample corpus**    | `./samples` – public-domain texts (≤ 10 MB)                               |
| **Embeddings model** | `text-embedding-3-small` (OpenAI) – 1536-d vectors, commercial license    |
| **Tokenizer**        | Automatically inferred via [tiktoken](https://github.com/openai/tiktoken) |
| **Checksums**        | Generated at ingest (`ingest.md5`)                                        |

*You can override the embedder with any model supported by [LangChain Embeddings](https://python.langchain.com/docs/integrations/text_embedding/).*

---

## Directory & File Reference

<details>
<summary>First-level tree</summary>

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
| [`llm/`](./llm/)                                   | Provider adapters (OpenAI, HF, local)    | LangChain wrappers                                                                 |
| [`models/`](./models/)                             | Pydantic DTOs / ORM models               | [`SQLModel`](https://sqlmodel.tiangolo.com/)                                       |
| [`parsers/`](./parsers/)                           | File-type handlers (PDF, HTML, Markdown) | PDFMiner, BeautifulSoup                                                            |
| [`utils/`](./utils/)                               | Common helpers (chunking, hashing)       | pure Python                                                                        |
| [`database/`](./database/)                         | SQL migrations, seeds                    | Alembic scripts                                                                    |
| [`test/`](./test/)                                 | Pytest suites & fixtures                 | [`pytest`](https://docs.pytest.org/)                                               |
| `init_stat.txt`                                    | Post-boot flag for Docker health-check   | shell                                                                              |
| `metadata_structure.md`                            | Doc schema reference                     | Markdown                                                                           |
| `tempCodeRunnerFile.py`                            | Scratch script (remove in prod)          | —                                                                                  |

> **Special files**
>
> * `.env.example` – template with all configurable variables.
> * `docker-compose.yml` – builds the API and a Postgres 15 image pre-loaded with `pgvector` extension.
> * `Makefile` – cross-platform task runner.

---

## Configuration

| Variable            | Default                  | Description                            |
| ------------------- | ------------------------ | -------------------------------------- |
| `POSTGRES_HOST`     | `localhost`              | DB endpoint                            |
| `POSTGRES_PORT`     | `5432`                   | —                                      |
| `POSTGRES_USER`     | `postgres`               | —                                      |
| `POSTGRES_PASSWORD` | `postgres`               | —                                      |
| `OPENAI_API_KEY`    | —                        | Required for OpenAI embeddings         |
| `EMBEDDING_MODEL`   | `text-embedding-3-small` | Any model string accepted by LangChain |
| `CHUNK_SIZE`        | `512`                    | Tokens per chunk                       |
| `MMR_K`             | `20`                     | Window size for MMR selection          |
| `TOP_K`             | `5`                      | Retrieval depth                        |

Create your own `.env` or pass vars via `docker compose --env-file`.

---

## Testing & Linting

```bash
# unit & integration
pytest -q

# static checks
ruff check .
ruff format .
```

Pre-commit hooks are defined in `.pre-commit-config.yaml`; run `pre-commit install` after cloning.

---

## Benchmarking

| Metric                       | Script                    | Notes                 |
| ---------------------------- | ------------------------- | --------------------- |
| Ingest throughput (docs/sec) | `scripts/bench_ingest.py` | CPU i7-12700H         |
| Query latency (P99)          | `scripts/bench_query.py`  | 100 parallel requests |

Output CSV is stored in `bench/` and can be plotted with `python scripts/plot.py`.

---

## Deployment

| Target             | Hint                                                        |
| ------------------ | ----------------------------------------------------------- |
| **Docker Compose** | `docker compose -f deploy/prod.yml up -d --scale api=3`     |
| **Kubernetes**     | See `charts/reldoc/values.yaml` for resources & autoscaling |
| **HF Spaces**      | Comment out Postgres, switch to `sqlite+aiosqlite://`       |
| **GPU box**        | Mount \`--gpus                                              |

## Contributing
We follow Conventional Commits + GitHub Flow.

1. feat/my-brief-topic branch off main

2. make fmt && make test must pass

3. Open PR, request review from @team-Budapest/owners

All code changes require matching unit tests.

##Roadmap
 PDF table extraction

 Vector-aware summarization endpoint

 Web UI (React + Intersection Observer for infinite scroll)

 BYO-embedding model via OCI image

 Bench suite on A100 vs CPU

## Authors & Acknowledgements
Made with ☕ by Team “Budapest”.
Big thanks to the OSS community behind FastAPI, pgvector, and LangChain.

## FAQ / Troubleshooting
| Question                                                     | Fix                                                                                 |
| ------------------------------------------------------------ | ----------------------------------------------------------------------------------- |
| **`psycopg2.OperationalError: could not connect to server`** | Ensure `docker compose ps` shows the `db` container healthy; check `POSTGRES_HOST`. |
| **`pgvector extension "vector" does not exist`**             | Run `CREATE EXTENSION IF NOT EXISTS vector;` or rebuild with `make docker-up`.      |
| **CUDA-enabled embedder OOM**                                | Lower `BATCH_SIZE` or switch to CPU model.                                          |
| **Tokenizer mismatch error**                                 | Delete `vector_cache/`, re-ingest with consistent model/version.                    |
| **CORS blocked in browser**                                  | Set `ALLOWED_ORIGINS=*` (dev) or whitelist domains.                                 |
| **UnicodeDecodeError on ingest**                             | Add `--encoding utf-8` flag or update `parsers/file_loader.py`.                     |
| **`SSL: WRONG_VERSION_NUMBER` on OpenAI**                    | `export OPENAI_API_BASE=https://api.openai.com/v1` or upgrade `openssl`.            |
| CLI hangs on Windows                                         | Use `winpty rel-doc ...` (Git Bash) or WSL.                                         |
| Inaccurate search results                                    | Increase `CHUNK_OVERLAP`, tune `TOP_K`, or enable hybrid mode.                      |
| Slow ingest                                                  | Raise `--num-workers`, mount SSD; disable per-chunk SHA-256 if not required.        |
