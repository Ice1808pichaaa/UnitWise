from firebase_functions import https_fn
from firebase_admin import initialize_app
import vertexai
from vertexai.generative_models import GenerativeModel
from google.cloud import vision
import json

PROJECT_ID = "manifest-chain-473423-f9"
LOCATION = "us-central1"

try:
    initialize_app()
except ValueError:
    pass

vertexai.init(project=PROJECT_ID, location=LOCATION)


def get_text_from_image_content(image_content):
    try:
        client = vision.ImageAnnotatorClient()
        image = vision.Image(content=image_content)
        response = client.document_text_detection(image=image)
        if response.error.message:
            raise Exception(f"Vision API Error: {response.error.message}")
        return response.full_text_annotation.text
    except Exception as e:
        print(f"An error occurred in get_text_from_image_content: {e}")
        return None

def get_advanced_comparison(product_texts):
    if not product_texts:
        return "Error: No text was provided to analyze."

    model = GenerativeModel("gemini-2.5-flash")
    
    prompt = f"""
        You are an expert value analyst. Output MUST be GitHub-flavored **Markdown** using the exact templates below.
        Do NOT use code fences. Keep it concise. Currency: USD (round money to 2 decimals; $/mg to ≤4 sig figs).

        NAMING RULES
        - Extract the real **brand** from OCR (e.g., Nature Made, Nature's Bounty, Organic Valley, Maple Hill). Do not invent brands.
        - If both products share the same brand, append a short **keyword** to distinguish (e.g., "Vitamin C chewable", "Vitamin C capsule", "Organic milk", "Non-organic milk").
        - If brands differ, use **BRAND – main product phrase** (e.g., "Nature Made – Vitamin C 1000 mg").
        - If brand truly missing, write **Unknown brand – <main product keyword>**.

        DETECTION
        - If products are vitamins/supplements (keywords: vitamin, supplement, mg, IU) → use SUPPLEMENT FORMAT.
        - Otherwise → use GROCERIES FORMAT.

        METRICS
        - If a metric cannot be computed, write **n/a**.
        - Supplements:
        - Total servings = (total tablets/caplets) ÷ (tablets-per-serving).
        - mg per serving = (mg per tablet) × (tablets-per-serving).
        - Compute **price per serving** and **price per mg** of the active vitamin.
        - Groceries: compute **price per volume** using the label’s unit (gallon, mL, L, etc.). Do not convert units.

        SUPPLEMENT FORMAT (use for vitamins/supplements)
        **Summary:** <one short sentence naming which product is better value and why (≤15 words)>
        split
        **Name:** **BRAND – KEYWORD**
        **Info:**
        - **Total Price:** <$X.XX or n/a>
        - **Total servings:** <N or n/a>
        - **Price per milligram:** <$X.XXXX/mg or n/a>
        - **Price per serving:** <$X.XX/serving; <N> mg/serving or n/a>
        split
        **Name:** **BRAND – KEYWORD**
        **Info:**
        - **Total Price:** <$X.XX or n/a>
        - **Total servings:** <N or n/a>
        - **Price per milligram:** <$X.XXXX/mg or n/a>
        - **Price per serving:** <$X.XX/serving; <N> mg/serving or n/a>
        split
        # If there is a Product 3, repeat the same block for Product 3.

        GROCERIES FORMAT (use when NOT supplements)
        **Summary:** <one short sentence naming which product is better value and why (≤15 words)>
        split
        **Name:** **BRAND – KEYWORD**
        **Info:**
        - **Price per volume (use unit from label):** <$X.XX per <unit> or n/a>
        split
        **Name:** **BRAND – KEYWORD**
        **Info:**
        - **Price per volume (use unit from label):** <$X.XX per <unit> or n/a>
        split
        # If there is a Product 3, repeat the same block for Product 3.
        
        Here is the text extracted from the product labels:
    {product_texts}

    --- ANALYSIS ---
    """
    try:
        response = model.generate_content(prompt)
        return response.text
    except Exception as e:
        print(f"An error occurred in get_advanced_comparison: {e}")
        return f"Gemini API Error: {e}"

@https_fn.on_request()
def advanced_product_analyzer_1(req: https_fn.Request) -> https_fn.Response:
    product_texts_for_prompt = ""
    
    for i in range(1, 4):
        product_key = f'product_{i}_images'
        image_files = req.files.getlist(product_key)
        
        if image_files:
            print(f"Found {len(image_files)} image(s) for Product {i}.")
            combined_text_for_this_product = ""
            
            for j, image_file in enumerate(image_files):
                image_content = image_file.read()
                print(f"  - OCR on image {j+1} for Product {i}...")
                extracted_text = get_text_from_image_content(image_content)
                if extracted_text:
                    combined_text_for_this_product += extracted_text + "\n"
            
            if combined_text_for_this_product:
                product_texts_for_prompt += f"--- TEXT FOR PRODUCT {i} ---\n{combined_text_for_this_product}\n\n"

    if not product_texts_for_prompt:
        error_response = {'error': 'No text could be extracted from any provided images.'}
        return https_fn.Response(json.dumps(error_response), status=500, mimetype="application/json")
        
    print("Sending all product text to Gemini for advanced analysis...")
    ai_analysis = get_advanced_comparison(product_texts_for_prompt)
    
    response_data = {'analysis': ai_analysis.strip()}
    return https_fn.Response(json.dumps(response_data), status=200, mimetype="application/json")