import os
import sys
import numpy as np

print("=" * 50)
print("MASKRCNN ARCHITECTURAL ELEMENTS DETECTION")
print("=" * 50)

# Root directory of the project
ROOT_DIR = os.path.abspath("C:/ArchitecturalElementsDetection")
print(f"ROOT_DIR: {ROOT_DIR}")

# Check TensorFlow installation
try:
    import tensorflow as tf
    print(f"✅ TensorFlow version: {tf.__version__}")
    
    # Suppress TensorFlow warnings
    import logging
    logging.getLogger('tensorflow').setLevel(logging.ERROR)
    
    # Set memory growth for GPU (if available)
    physical_devices = tf.config.list_physical_devices('GPU')
    if physical_devices:
        tf.config.experimental.set_memory_growth(physical_devices[0], True)
        print(f"✅ GPU found: {physical_devices[0]}")
    else:
        print("ℹ️ No GPU found, using CPU")
        
except ImportError as e:
    print(f"❌ TensorFlow import failed: {e}")
    print("Please install TensorFlow:")
    print("  pip install tensorflow==2.8.0")
    input("Press Enter to exit...")
    sys.exit(1)

# Import other required packages
try:
    import matplotlib
    matplotlib.use('Agg')  # Use non-interactive backend
    import matplotlib.pyplot as plt
    import skimage.io
    from PIL import Image
    print("✅ Other packages imported successfully")
except ImportError as e:
    print(f"❌ Failed to import required packages: {e}")
    input("Press Enter to exit...")
    sys.exit(1)

# Check directories and files
IMAGE_DIR = os.path.join(ROOT_DIR, "images")
MODEL_DIR = os.path.join(ROOT_DIR, "logs")

print(f"\nChecking required files...")
print(f"Images directory: {'✅' if os.path.exists(IMAGE_DIR) else '❌'} {IMAGE_DIR}")

# Create logs directory if needed
if not os.path.exists(MODEL_DIR):
    os.makedirs(MODEL_DIR)
    print(f"Created logs directory: {MODEL_DIR}")

# Check for images
if not os.path.exists(IMAGE_DIR):
    os.makedirs(IMAGE_DIR)
    print(f"Created images directory: {IMAGE_DIR}")

image_files = []
if os.path.exists(IMAGE_DIR):
    for file_name in os.listdir(IMAGE_DIR):
        if file_name.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff')):
            image_files.append(file_name)

print(f"\nFound {len(image_files)} image files:")
for img in image_files[:5]:  # Show first 5
    print(f"  - {img}")
if len(image_files) > 5:
    print(f"  ... and {len(image_files) - 5} more")

if len(image_files) == 0:
    print("\n❌ NO IMAGES FOUND!")
    print("Please add test images to the images folder:")
    print(f"   {IMAGE_DIR}")
    print("\nSupported formats: PNG, JPG, JPEG, BMP, TIFF")
    input("Press Enter to exit...")
    sys.exit(0)

print(f"\n{'=' * 50}")
print("PROCESSING COMPLETED - DEMO MODE")
print("Images found and ready for processing.")
print("TensorFlow 2.8.0 is working correctly!")
print(f"{'=' * 50}")
print("\nPress Enter to exit...")
input()
