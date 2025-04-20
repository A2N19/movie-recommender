FROM python:3.9-slim
WORKDIR /app
COPY etl.py .
RUN pip install pandas psycopg2-binary minio
CMD ["python", "etl.py"]
