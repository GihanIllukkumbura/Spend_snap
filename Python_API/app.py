from flask import Flask, request, jsonify
import pytesseract
from PIL import Image
import re
import requests
from io import BytesIO
import pickle
from tensorflow.keras.models import load_model
from sklearn.feature_extraction.text import TfidfVectorizer
from collections import Counter
import numpy as np
import os

app = Flask(__name__)

# Disable oneDNN optimizations (if needed)
os.environ['TF_ENABLE_ONEDNN_OPTS'] = '0'

# Specify the path to Tesseract executable
pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'  # Adjust for your OS

# Load the saved classification model, label encoder, and vectorizer
model = load_model("classification_model.h5")
with open("label_encoder.pkl", "rb") as f:
    label_encoder = pickle.load(f)
with open("vectorizer.pkl", "rb") as f:
    vectorizer = pickle.load(f)

# Function to extract raw text using Tesseract OCR
def extract_text_tesseract(image):
    try:
        print("Extracting text using Tesseract OCR...")
        text = pytesseract.image_to_string(image, lang="eng")
        return text.strip()
    except Exception as e:
        print(f"Error during text extraction: {e}")
        return None

# Function to parse items and prices using NLP and classify them
def parse_receipt_with_nlp(text):
    if not text:
        return [], None, None

    lines = text.splitlines()
    items = []
    total_price = None
    total_category = None

    # List of terms to ignore
    ignore_terms = ['tax', 'vat', 'service charge', 'tip', 'subtotal', 'discount','sbiotal']

    for line in lines:
        line = line.strip()
        if not line:
            continue

        print(f"Processing line: {line}")

        # Match items with prices using regex
        match = re.search(r"(.+?)\s+(\d+\.\d{2})$", line)
        if match:
            item = match.group(1).strip().lower()  # Convert to lowercase for case-insensitive comparison
            try:
                price = float(match.group(2))
            except ValueError:
                continue

            # Check if the item contains any of the ignore terms
            if any(term in item for term in ignore_terms):
                continue

            # Predict category using the classification model
            item_vectorized = vectorizer.transform([item])
            prediction = model.predict(item_vectorized.toarray())
            predicted_class = label_encoder.inverse_transform([np.argmax(prediction)])[0]

            items.append({'name': item, 'price': price, 'category': predicted_class})

        # Match total (case insensitive)
        if 'total' in line.lower():
            total_match = re.search(r"\d+\.\d{2}", line)
            if total_match:
                try:
                    total_price = float(total_match.group(0))
                except ValueError:
                    pass

    # Determine total_price category based on majority category of items
    if items:
        category_counts = Counter(item['category'] for item in items)
        total_category = category_counts.most_common(1)[0][0]

    return items, total_price, total_category

@app.route('/parse_receipt', methods=['POST'])
def parse_receipt():
    try:
        data = request.json
        image_url = data.get('image_url')

        if not image_url:
            return jsonify({'error': 'No image URL provided'}), 400

        # Download the image from the URL
        response = requests.get(image_url)
        if response.status_code != 200:
            return jsonify({'error': 'Failed to download image'}), 400

        image = Image.open(BytesIO(response.content))

        # Step 1: Extract text using Tesseract
        text = extract_text_tesseract(image)
        if not text:
            return jsonify({'error': 'Failed to extract text from the image'}), 500

        # Step 2: Parse the items and total price
        items, total_price, total_category = parse_receipt_with_nlp(text)

        return jsonify({
            'items': items,
            'total_price': total_price,
            'total_category': total_category
        })
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)