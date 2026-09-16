import time
import os

from flask import Flask, jsonify, abort
from flask_cors import CORS
from sqlalchemy.exc import OperationalError
from db import db
from models import Product
from urllib.parse import quote

app = Flask(__name__)
CORS(app)


DB_USER = os.environ.get('POSTGRES_USER', 'homeoffice')
DB_PASSWORD = os.environ.get('POSTGRES_PASSWORD', 'homeoffice123')
DB_HOST = os.environ.get('DB_HOST', 'db')
DB_PORT = os.environ.get('DB_PORT', '5432')
DB_NAME = os.environ.get('POSTGRES_DB', 'homeoffice_db')

app.config['SQLALCHEMY_DATABASE_URI'] = f'postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}'

app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db.init_app(app)

# ---------- Wait for database to be ready ----------
def wait_for_db(max_retries=15, delay=2):
    """Try to connect to the database; retry if it's not ready yet."""
    for i in range(max_retries):
        try:
            with app.app_context():
                with db.engine.connect() as conn:
                    conn.execute(db.text("SELECT 1"))
            print("Database is ready!")
            return
        except OperationalError:
            print(f"Database not ready, retrying in {delay}s ({i+1}/{max_retries})...")
            time.sleep(delay)
    raise Exception("Could not connect to the database after several retries.")

with app.app_context():
    wait_for_db()
    db.create_all()          # Creates tables if they don't exist
    if not Product.query.first():
        # Seed database on first run
        def commons_file(filename: str) -> str:
            return f"https://commons.wikimedia.org/wiki/Special:FilePath/{quote(filename, safe='')}"

        products_data = [
            {"name": "Wireless Mouse", "price": 19.99, "image": commons_file("Microsoft-wireless-mouse.jpg"),
             "description": "Ergonomic wireless mouse with silent clicks and long battery life. Perfect for all‑day comfort."},
            {"name": "Mechanical Keyboard", "price": 79.99, "image": commons_file("Mechanical Keyboard.jpg"),
             "description": "Satisfying mechanical switches with customizable RGB backlighting. Built for speed and precision."},
            {"name": "USB-C Hub", "price": 34.99, "image": commons_file("USB-C Hubb 5 portar.jpg"),
             "description": "Compact 5‑in‑1 USB‑C hub with HDMI, USB‑A, and SD card slots. Expand your laptop instantly."},
            {"name": "Noise-Canceling Headphones", "price": 129.99, "image": commons_file("Bose QuietComfort 25 Acoustic Noise Cancelling Headphones.jpg"),
             "description": "Industry‑leading noise cancellation for deep focus. Plush ear cushions for all‑day wear."},
            {"name": "27\" 4K Monitor", "price": 349.99, "image": commons_file("Monitor-Eizo-CG277-BK-27inches-01.jpg"),
             "description": "Crystal‑clear 4K resolution with ultra‑thin bezels. Ideal for multitasking and creative work."},
            {"name": "Portable Bluetooth Speaker", "price": 44.99, "image": commons_file("Beats By Dr. Dre Pill Portable Bluetooth Speaker Black N2.jpg"),
             "description": "Rich, room‑filling sound in a pocket‑sized design. Water‑resistant and ready for any space."},
            {"name": "Webcam 1080p", "price": 59.99, "image": commons_file("Webcam 01.jpg"),
             "description": "Full HD webcam with auto‑focus and built‑in privacy shutter. Look your best on every call."},
            {"name": "Laptop Stand", "price": 29.99, "image": commons_file("Laptop stand.jpg"),
             "description": "Elevate your screen to eye level with this sturdy, ventilated aluminium stand. Reduce neck strain."},
            {"name": "Standing Desk with Treadmill", "price": 899.99, "image": commons_file("Treadmill Desk (17219566739).jpg"),
             "description": "Stay active while you work – a height‑adjustable desk with an integrated treadmill. Walk at your own pace."},
            {"name": "Ergonomic Office Chair", "price": 399.99, "image": commons_file("ErgoFlip Active Ergonomic Chair eye view.jpg"),
             "description": "Adjustable lumbar support, breathable mesh, and a waterfall seat edge. Designed for all‑day comfort."},
            {"name": "Blue Light Blocking Glasses", "price": 39.99, "image": commons_file("Glasses&Chart.jpg"),
             "description": "Reduce digital eye strain with premium blue‑light‑filtering lenses. Lightweight and stylish."},
            {"name": "Desk LED Lamp with Wireless Charger", "price": 49.99, "image": commons_file("Dekala Arches™ Smart Lamp.jpg"),
             "description": "Adjustable brightness and colour temperature. Built‑in 10W wireless charger keeps your phone topped up."},
            {"name": "Soundproof Wall Panels (Set of 4)", "price": 89.99, "image": commons_file("Studio soundproofing panel.jpg"),
             "description": "Dense acoustic foam panels that reduce echo and external noise. Easy peel‑and‑stick installation."},
            {"name": "Smart Coffee Mug (Temperature Control)", "price": 74.99, "image": commons_file("Ember Smart Mug (24477264215).jpg"),
             "description": "Keep your coffee at the perfect temperature with app‑controlled precision. All‑day battery life."},
        ]
        for p in products_data:
            product = Product(name=p["name"], price=p["price"], image=p["image"], description=p["description"])
            db.session.add(product)
        db.session.commit()
        print("Database seeded with initial products.")
# ------------------------------------------------

@app.route('/')
def home():
    return "HomeOffice Hub API is running!"

@app.route('/api/products')
def get_products():
    products = Product.query.all()
    return jsonify([p.to_dict() for p in products])

@app.route('/api/products/<int:product_id>')
def get_product(product_id):
    product = Product.query.get(product_id)
    if product:
        return jsonify(product.to_dict())
    else:
        abort(404)

@app.route('/healthz')
def healthz():
    return jsonify(status="ok"), 200

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)