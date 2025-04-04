from airflow import DAG
from airflow.operators.python import PythonOperator
from datetime import datetime
import requests
from pymongo import MongoClient

API_KEY = "935d684d3c3557ba72035cbda369a894"
CITY = "London"
MONGO_URI = "mongodb://host.docker.internal:27017/"
DB_NAME = "weatherDB"
COLLECTION_NAME = "weatherData"

def fetch_weather():
    url = f"http://api.openweathermap.org/data/2.5/weather?q={CITY}&appid={API_KEY}&units=metric"
    response = requests.get(url)
    response.raise_for_status()
    return response.json()

def store_in_mongo(**context):
    weather_data = context['ti'].xcom_pull(task_ids='fetch_weather')
    client = MongoClient(MONGO_URI)
    db = client[DB_NAME]
    collection = db[COLLECTION_NAME]
    collection.insert_one(weather_data)
    client.close()

with DAG(
    dag_id='weather_to_mongo',
    start_date=datetime(2024, 1, 1),
    schedule_interval='@hourly',
    catchup=False,
) as dag:

    fetch_weather_task = PythonOperator(
        task_id='fetch_weather',
        python_callable=fetch_weather,
    )

    store_task = PythonOperator(
        task_id='store_in_mongo',
        python_callable=store_in_mongo,
        provide_context=True
    )

    fetch_weather_task >> store_task
