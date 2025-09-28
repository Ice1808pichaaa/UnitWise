import os
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from functions.main import get_text_from_image_content, get_advanced_comparison
except ImportError:
    print("FATAL ERROR: Could not import from 'functions/main.py'.")
    print("Please make sure this test script is saved in your 'HACKGT' root folder,")
    print("and your Firebase function code is located at 'HACKGT/functions/main.py'.")
    sys.exit(1)

PRODUCTS_TO_TEST = {
    "Product 1 (Brand A)": [
        'p1_1.jpg', 
        'p1.jpg', 
    ],
    "Product 2 (Brand B)": [
        'p2_1.jpg', 
        'p2.jpg',
    ],
}

def run_local_end_to_end_test():
    print("--- Starting Full Local End-to-End Test ---")
    
    product_texts_for_prompt = ""

    for i, (product_name, image_files) in enumerate(PRODUCTS_TO_TEST.items()):
        print(f"\n[ OCR ] Processing {product_name} with {len(image_files)} image(s)...")
        combined_text_for_product = ""

        for file_name in image_files:
            image_path = os.path.join(os.path.dirname(__file__), file_name)
            try:
                with open(image_path, "rb") as image_file:
                    image_content = image_file.read()
                
                print(f"  - Calling Vision API for '{file_name}'...")
                extracted_text = get_text_from_image_content(image_content)
                if extracted_text:
                    print(f"  - Success: Extracted text from '{file_name}'.")
                    combined_text_for_product += extracted_text + "\n"
                else:
                    print(f"  - Warning: No text was returned for '{file_name}'.")

            except FileNotFoundError:
                print(f"\nFATAL ERROR: The file '{file_name}' was not found in your 'HACKGT' folder.")
                print("Please add the image and try again.")
                return
        
        if combined_text_for_product:
            product_texts_for_prompt += f"--- TEXT FOR PRODUCT {i+1} ({product_name}) ---\n{combined_text_for_product}\n\n"

    if not product_texts_for_prompt:
        print("\nHALTING: No text could be extracted from any of the provided images. Cannot proceed to Gemini analysis.")
        return

    print("\n[ Gemini ] Sending all combined OCR text to the Gemini API for advanced analysis...")
    ai_analysis = get_advanced_comparison(product_texts_for_prompt)

    print("\n" + "="*40)
    print("✅ AI Analysis Complete")
    print("="*40)
    print("Gemini's Value Comparison Analysis:")
    print("-" * 40)
    print(ai_analysis.strip())
    print("-" * 40)
    print("="*40)


if __name__ == "__main__":
    if os.getenv('GOOGLE_APPLICATION_CREDENTIALS') or os.path.exists(os.path.expanduser('~/.config/gcloud/application_default_credentials.json')):
        run_local_end_to_end_test()
    else:
        print("--- AUTHENTICATION ERROR ---")
        print("You are not logged in. Please run the following command in your terminal first:")
        print("\ngcloud auth application-default login\n")

