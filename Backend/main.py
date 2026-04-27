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

# Used to search for movies
