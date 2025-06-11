import os
import sys
import numpy as np
import tensorflow as tf
import matplotlib.pyplot as plt
import skimage.io
from PIL import Image

# Root directory of the project
ROOT_DIR = os.path.abspath("C:/Users/Enes/PycharmProjects/Mask_RCNN-Multi-Class-Detection")

# Import Mask RCNN
sys.path.append(ROOT_DIR)  # To find local version of the library
from mrcnn import utils, visualize
import mrcnn.model as modellib
from mrcnn.model import log

import food

# Directory to save logs and trained model
MODEL_DIR = os.path.join(ROOT_DIR, "logs")

# Path to Food trained weights
FOOD_WEIGHTS_PATH = "//Nb/Enes Doktora/Tubitak/Experiments/Deney 8-/12/food20240330T1846/mask_rcnn_food_0029.h5"

class InferenceConfig(food.FoodConfig):
    GPU_COUNT = 1
    IMAGES_PER_GPU = 1
    DETECTION_MIN_CONFIDENCE = 0.8

def load_model():
    config = InferenceConfig()
    config.display()

    # Create model in inference mode
    with tf.device("/cpu:0"):
        model = modellib.MaskRCNN(mode="inference", model_dir=MODEL_DIR, config=config)

    print("Loading weights ", FOOD_WEIGHTS_PATH)
    model.load_weights(FOOD_WEIGHTS_PATH, by_name=True)
    return model

def load_images(image_dir):
    file_names = next(os.walk(image_dir))[2]
    return file_names, [skimage.io.imread(os.path.join(image_dir, file_name)) for file_name in file_names]

def main():
    model = load_model()

    # Load validation dataset
    dataset = food.FoodDataset()
    dataset.load_food(os.path.join(ROOT_DIR, "Food"), "val")
    dataset.prepare()

    print("Images: {}\nClasses: {}".format(len(dataset.image_ids), dataset.class_names))

    IMAGE_DIR = os.path.join(ROOT_DIR, "images")
    file_names, images = load_images(IMAGE_DIR)

    # Process each image in the directory
    for file_name, image in zip(file_names, images):
        # Run detection
        results = model.detect([image], verbose=1)

        # Get detection results
        r = results[0]

        # Create a directory for saved masks if it doesn't exist
        mask_dir = os.path.join(ROOT_DIR, "SavedMasks")
        if not os.path.exists(mask_dir):
            os.makedirs(mask_dir)

        # Save each mask with the image name and class name as the filename
        for i in range(r['masks'].shape[-1]):
            mask = r['masks'][:, :, i]
            class_id = r['class_ids'][i]
            class_name = dataset.class_names[class_id]
            mask_image = Image.fromarray((mask * 255).astype('uint8'))
            mask_image_filename = f"{os.path.splitext(file_name)[0]}_{class_name}_{i}.png"
            mask_image.save(os.path.join(mask_dir, mask_image_filename))

        # Visualize results with all masks displayed on the original image
        fig, ax = plt.subplots(1, figsize=(12, 12))
        visualize.display_instances(image, r['rois'], r['masks'], r['class_ids'],
                                    dataset.class_names, r['scores'], ax=ax)

        # Save the visualization with a unique name for each image
        results_image_filename = f"detection_result_{os.path.splitext(file_name)[0]}.png"
        fig.savefig(os.path.join(mask_dir, results_image_filename))
        plt.close(fig)

if __name__ == "__main__":
    main()


from PIL import Image
import os

def convert_png_to_jpeg(folder_path, alpha_threshold=127):
    for filename in os.listdir(folder_path):
        if filename.endswith(".png"):
            file_path = os.path.join(folder_path, filename)
            # Resmi aç
            with Image.open(file_path) as img:
                img = img.convert("RGBA")  # Alpha kanalını dahil etmek için
                # Yeni bir görüntü oluştur
                new_img = Image.new("RGB", img.size, "white")
                pixels = new_img.load()

                # Her pikseli kontrol et
                for y in range(img.size[1]):
                    for x in range(img.size[0]):
                        r, g, b, a = img.getpixel((x, y))
                        if a > alpha_threshold:  # Alfa değeri eşik değerinin üzerindeyse
                            pixels[x, y] = (0, 0, 0)  # Siyah yap
                        else:
                            pixels[x, y] = (255, 255, 255)  # Beyaz yap

                # Yeni dosya adı oluştur
                new_filename = filename.replace(".png", ".jpg")
                new_file_path = os.path.join(folder_path, new_filename)

                # Yeni resmi kaydet
                new_img.save(new_file_path, "JPEG")
                print(f"Saved {new_file_path}")

# Kullanım
folder_path = "images"  # Klasör yolunu buraya yazın
convert_png_to_jpeg(folder_path)

