FROM python:3.9-slim
WORKDIR /app
COPY app.py .
RUN pip install flask flask-cors psycopg2-binary pandas
CMD ["python", "app.py"]
