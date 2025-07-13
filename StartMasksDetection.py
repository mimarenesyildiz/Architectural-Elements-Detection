#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Enhanced Mask R-CNN Detection for Architectural Elements
Optimized for building facade analysis with improved accuracy
"""

import os
import sys
import random
import math
import numpy as np
import skimage.io
import skimage.transform
import skimage.color
import matplotlib
matplotlib.use('Agg')  # Use non-interactive backend
import matplotlib.pyplot as plt
try:
    import cv2
except ImportError:
    logger.warning('OpenCV (cv2) not found. Some mask processing features may be limited.')
    cv2 = None
import time
import scipy.ndimage
import json
from datetime import datetime
import logging

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

# Root directory of the project
ROOT_DIR = os.path.abspath('.')
sys.path.append(ROOT_DIR)

# Import Mask RCNN
from mrcnn import utils
import mrcnn.model as modellib
from mrcnn import visualize
from mrcnn.config import Config

# Import custom configs - we'll handle missing FoodConfig
try:
    from food import FoodConfig, FoodDataset
except ImportError:
    logger.warning('Custom food module not found. Using default configuration.')
    # Define a minimal config class for inference
    class FoodConfig(Config):
        """Configuration for inference on architectural elements"""
        NAME = "food"
        IMAGES_PER_GPU = 1
        NUM_CLASSES = 1 + 7  # Background + 7 architectural classes (from food.py)
        DETECTION_MIN_CONFIDENCE = 0.9

# Disable GPU warnings if CUDA not available
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'

try:
    import tensorflow as tf
    # Check GPU availability
    if not tf.test.is_gpu_available():
        logger.info('GPU not available, using CPU')
        os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
    else:
        logger.info('GPU detected and available')
        # Limit GPU memory growth
        gpus = tf.config.experimental.list_physical_devices('GPU')
        if gpus:
            try:
                for gpu in gpus:
                    tf.config.experimental.set_memory_growth(gpu, True)
            except RuntimeError as e:
                logger.warning(f'GPU memory configuration failed: {e}')
except ImportError:
    logger.error('TensorFlow not found! Please install tensorflow==1.10.0')
    sys.exit(1)

# Directories
MODEL_DIR = os.path.join(ROOT_DIR, 'logs')
SAVE_DIR = os.path.join(ROOT_DIR, 'SavedMasks')
IMAGE_DIR = os.path.join(ROOT_DIR, 'images')

# Ensure directories exist
for dir_path in [MODEL_DIR, SAVE_DIR]:
    if not os.path.exists(dir_path):
        os.makedirs(dir_path)


class InferenceConfig(FoodConfig):
    """Configuration for inference optimized for architectural elements"""
    
    # Set batch size to 1 since we're inferring on one image at a time
    GPU_COUNT = 1
    IMAGES_PER_GPU = 1
    
    # Use same confidence threshold as FoodConfig (0.9)
    # DETECTION_MIN_CONFIDENCE is already set in FoodConfig
    
    # Optimized image dimensions for architectural plans
    IMAGE_MAX_DIM = 1024
    IMAGE_MIN_DIM = 800
    
    # Non-maximum suppression threshold
    DETECTION_NMS_THRESHOLD = 0.3
    
    # Maximum number of ground truth instances
    MAX_GT_INSTANCES = 200
    
    # ROI settings for better detection
    POST_NMS_ROIS_INFERENCE = 1000
    DETECTION_MAX_INSTANCES = 100


def get_class_names():
    """Get class names for the model - with fallback options"""
    # First, try to get from FoodDataset
    try:
        from food import FoodDataset
        # Create a temporary dataset instance to extract class names
        temp_dataset = FoodDataset()
        # Initialize the dataset with dummy values just to get class names
        temp_dataset.add_class("food", 1, "Wall")
        temp_dataset.add_class("food", 2, "Door")
        temp_dataset.add_class("food", 3, "GlassDoor")
        temp_dataset.add_class("food", 4, "Window")
        temp_dataset.add_class("food", 5, "Floor")
        temp_dataset.add_class("food", 6, "Ceramic")
        temp_dataset.add_class("food", 7, "Carpet")
        
        # Get class names from the dataset
        class_names = ['BG']  # Background is always first
        for i in range(1, 8):  # 7 classes from food.py
            class_info = temp_dataset.class_info[i]
            class_names.append(class_info['name'])
        
        logger.info(f'Loaded {len(class_names)-1} classes from food.py')
        return class_names
    except Exception as e:
        logger.warning(f'Could not load classes from food.py: {e}')
    
    # Second, try to read from a config file if it exists
    config_files = ['class_names.txt', 'classes.txt', 'labels.txt']
    for config_file in config_files:
        if os.path.exists(config_file):
            try:
                with open(config_file, 'r', encoding='utf-8') as f:
                    class_names = ['BG'] + [line.strip() for line in f if line.strip()]
                logger.info(f'Loaded {len(class_names)-1} classes from {config_file}')
                return class_names
            except Exception as e:
                logger.warning(f'Could not read {config_file}: {e}')
    
    # Default architectural element classes from food.py
    logger.info('Using default architectural element classes')
    return ['BG', 'Wall', 'Door', 'GlassDoor', 'Window', 'Floor', 'Ceramic', 'Carpet']


def preprocess_image(image_path):
    """Enhanced image preprocessing for architectural elements"""
    try:
        # Read image
        image = skimage.io.imread(image_path)
        logger.info(f'Loaded image: {image.shape}')
        
        # Handle different image formats
        if len(image.shape) == 2:
            # Grayscale to RGB
            image = skimage.color.gray2rgb(image)
        elif len(image.shape) == 3 and image.shape[2] == 4:
            # RGBA to RGB
            image = image[:, :, :3]
        
        # Ensure uint8 format
        if image.dtype != np.uint8:
            if image.max() <= 1.0:
                image = (image * 255).astype(np.uint8)
            else:
                image = image.astype(np.uint8)
        
        # Image enhancement for better detection
        if image.shape[0] > 2048 or image.shape[1] > 2048:
            # Resize very large images
            max_dim = 2048
            scale = min(max_dim / image.shape[0], max_dim / image.shape[1])
            new_height = int(image.shape[0] * scale)
            new_width = int(image.shape[1] * scale)
            image = skimage.transform.resize(image, (new_height, new_width), 
                                           preserve_range=True, anti_aliasing=True).astype(np.uint8)
            logger.info(f'Resized image to: {image.shape}')
        
        return image
    except Exception as e:
        logger.error(f'Error preprocessing image {image_path}: {e}')
        return None


def enhance_mask(mask, method='morphological', expand_pixels=15):
    """Enhanced mask processing with multiple methods"""
    if mask.sum() == 0:
        return mask
    
    # Convert to uint8 if needed
    mask_uint8 = (mask * 255).astype(np.uint8) if mask.dtype == bool else mask
    
    if cv2 is None:
        # Fallback without OpenCV - use scipy
        from scipy import ndimage
        if method == 'morphological':
            # Simple dilation using scipy
            struct = ndimage.generate_binary_structure(2, 2)
            enhanced = ndimage.binary_dilation(mask, structure=struct, iterations=expand_pixels//3)
            return enhanced.astype(bool)
        else:
            return mask
    
    if method == 'morphological':
        # Advanced morphological operations
        kernel_dilate = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (expand_pixels, expand_pixels))
        kernel_close = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (expand_pixels//2, expand_pixels//2))
        
        # Dilate to expand
        enhanced = cv2.dilate(mask_uint8, kernel_dilate, iterations=1)
        
        # Close to fill gaps
        enhanced = cv2.morphologyEx(enhanced, cv2.MORPH_CLOSE, kernel_close)
        
        # Remove noise
        enhanced = cv2.medianBlur(enhanced, 5)
        
    elif method == 'gaussian':
        # Gaussian-based expansion
        enhanced = cv2.GaussianBlur(mask_uint8.astype(np.float32), (expand_pixels, expand_pixels), 0)
        enhanced = (enhanced > 128).astype(np.uint8) * 255
        
    else:  # 'none'
        enhanced = mask_uint8
    
    return (enhanced > 128).astype(bool)


def create_enhanced_visualization(image, results, class_names, save_path):
    """Create high-quality visualization with architectural focus"""
    try:
        fig, ax = plt.subplots(1, figsize=(16, 12))
        
        # Enhanced visualization settings
        visualize.display_instances(
            image, results['rois'], results['masks'], results['class_ids'],
            class_names, results['scores'], ax=ax,
            title='Architectural Elements Detection',
            show_bbox=True, show_mask=True
        )
        
        # Add detection statistics
        stats_text = f'Detected Elements: {len(results["class_ids"])}\n'
        for class_id in np.unique(results['class_ids']):
            count = np.sum(results['class_ids'] == class_id)
            if class_id < len(class_names):
                stats_text += f'{class_names[class_id]}: {count}\n'
            else:
                stats_text += f'Class {class_id}: {count}\n'
        
        # Add text using matplotlib's text function
        plt.text(0.02, 0.98, stats_text, transform=ax.transAxes, fontsize=10,
                verticalalignment='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.8))
        
        plt.tight_layout()
        plt.savefig(save_path, dpi=150, bbox_inches='tight', facecolor='white')
        plt.close()
        logger.info(f'Visualization saved: {save_path}')
        
    except Exception as e:
        logger.error(f'Error creating visualization: {e}')


def main():
    """Enhanced main function with comprehensive error handling"""
    print('=' * 80)
    print('ENHANCED MASK R-CNN ARCHITECTURAL ELEMENTS DETECTION')
    print('=' * 80)
    print()
    
    # Initialize tracking variables
    start_time = time.time()
    processed_count = 0
    error_count = 0
    
    try:
        # Find model file
        model_files = [f for f in os.listdir(ROOT_DIR) if f.endswith('.h5')]
        if not model_files:
            logger.error('No .h5 model file found!')
            print('ERROR: No .h5 model file found in:', ROOT_DIR)
            input('Press Enter to exit...')
            return
        
        MODEL_PATH = os.path.join(ROOT_DIR, model_files[0])
        logger.info(f'Using model: {model_files[0]}')
        print(f'📁 Model: {model_files[0]}')
        
        # Get class names
        class_names = get_class_names()
        print(f'📋 Classes: {len(class_names)-1} types detected')
        print(f'   Classes: {", ".join(class_names[1:])}')  # Skip BG
        
        # Configuration
        config = InferenceConfig()
        # NUM_CLASSES is already set correctly from FoodConfig (8 classes)
        config.display()
        
        # Create model
        logger.info('Loading Mask R-CNN model...')
        print('\n🤖 Loading Mask R-CNN model...')
        model = modellib.MaskRCNN(mode='inference', config=config, model_dir=MODEL_DIR)
        
        # Load weights
        logger.info('Loading model weights...')
        model.load_weights(MODEL_PATH, by_name=True)
        print('✅ Model loaded successfully!')
        
        # Warm up the model
        logger.info('Warming up model...')
        print('🔥 Warming up model...')
        dummy_image = np.zeros((config.IMAGE_MIN_DIM, config.IMAGE_MAX_DIM, 3), dtype=np.uint8)
        _ = model.detect([dummy_image], verbose=0)
        print('✅ Model ready for detection!')
        
        # Get image files
        if not os.path.exists(IMAGE_DIR):
            logger.error(f'Images directory not found: {IMAGE_DIR}')
            print(f'ERROR: Images directory not found: {IMAGE_DIR}')
            input('Press Enter to exit...')
            return
        
        file_names = [f for f in os.listdir(IMAGE_DIR) 
                      if f.lower().endswith(('.png', '.jpg', '.jpeg', '.bmp', '.tiff', '.tif'))]
        
        if not file_names:
            logger.warning(f'No images found in: {IMAGE_DIR}')
            print(f'\n⚠️ No images found in: {IMAGE_DIR}')
            print('Please add images and try again.')
            input('Press Enter to exit...')
            return
        
        logger.info(f'Found {len(file_names)} images to process')
        print(f'\n📸 Found {len(file_names)} images to process')
        print('\n🚀 Starting enhanced detection process...\n')
        
        # Process each image
        all_results = {}
        
        for idx, file_name in enumerate(file_names):
            try:
                print(f'[{idx+1}/{len(file_names)}] Processing: {file_name}')
                logger.info(f'Processing image {idx+1}/{len(file_names)}: {file_name}')
                
                # Preprocess image
                image_path = os.path.join(IMAGE_DIR, file_name)
                image = preprocess_image(image_path)
                
                if image is None:
                    error_count += 1
                    continue
                
                # Run detection
                detection_start = time.time()
                results = model.detect([image], verbose=0)[0]
                detection_time = time.time() - detection_start
                
                logger.info(f'Detected {len(results["class_ids"])} objects in {detection_time:.2f}s')
                print(f'  🎯 Detected {len(results["class_ids"])} objects in {detection_time:.2f}s')
                
                # Store results
                base_name = os.path.splitext(file_name)[0]
                image_results = {
                    'file_name': file_name,
                    'detection_time': detection_time,
                    'image_size': image.shape,
                    'objects': []
                }
                
                # Create enhanced visualization
                viz_path = os.path.join(SAVE_DIR, f'enhanced_visualization_{base_name}.png')
                create_enhanced_visualization(image, results, class_names, viz_path)
                
                # Process each detection
                for i in range(len(results['class_ids'])):
                    class_id = results['class_ids'][i]
                    if class_id < len(class_names):
                        class_name = class_names[class_id]
                    else:
                        class_name = f'class_{class_id}'
                    score = results['scores'][i]
                    mask = results['masks'][:, :, i]
                    bbox = results['rois'][i]
                    
                    # Enhanced mask processing based on element type
                    if class_name.lower() in ['window', 'door', 'glassdoor']:
                        enhanced_mask = enhance_mask(mask, 'morphological', 20)
                    elif class_name.lower() in ['wall', 'floor', 'ceramic', 'carpet']:
                        enhanced_mask = enhance_mask(mask, 'morphological', 10)
                    else:
                        enhanced_mask = enhance_mask(mask, 'morphological', 15)
                    
                    # Save individual enhanced mask
                    mask_filename = f'enhanced_mask_{base_name}_{class_name}_{i:02d}.png'
                    mask_path = os.path.join(SAVE_DIR, mask_filename)
                    mask_uint8 = (enhanced_mask * 255).astype(np.uint8)
                    if cv2 is not None:
                        cv2.imwrite(mask_path, mask_uint8)
                    else:
                        # Fallback using skimage
                        skimage.io.imsave(mask_path, mask_uint8)
                    
                    # Store object information
                    obj_info = {
                        'class': class_name,
                        'confidence': float(score),
                        'bbox': bbox.tolist(),
                        'mask_file': mask_filename,
                        'mask_area': int(np.sum(enhanced_mask)),
                        'bbox_area': int((bbox[2] - bbox[0]) * (bbox[3] - bbox[1]))
                    }
                    image_results['objects'].append(obj_info)
                    
                    print(f'    • {class_name}: {score:.3f} confidence')
                
                all_results[file_name] = image_results
                
                # Create directional masks for Grasshopper
                for direction in ['East', 'West', 'North', 'South', 'Down', 'Up']:
                    if direction.lower() in base_name.lower():
                        combined_mask = np.zeros_like(image[:, :, 0], dtype=np.uint8)
                        for i in range(len(results['class_ids'])):
                            mask = results['masks'][:, :, i]
                            enhanced_mask = enhance_mask(mask, 'morphological', 15)
                            combined_mask = np.maximum(combined_mask, 
                                                      (enhanced_mask * 255).astype(np.uint8))
                        
                        direction_mask_path = os.path.join(SAVE_DIR, f'detection_result_{direction}.png')
                        if cv2 is not None:
                            cv2.imwrite(direction_mask_path, combined_mask)
                        else:
                            # Fallback using skimage
                            skimage.io.imsave(direction_mask_path, combined_mask)
                        print(f'    📁 Saved directional mask: {direction}')
                
                processed_count += 1
                
            except Exception as e:
                logger.error(f'Error processing {file_name}: {e}')
                print(f'  ❌ Error processing {file_name}: {e}')
                error_count += 1
                continue
        
        # Save comprehensive results
        summary_path = os.path.join(SAVE_DIR, 'enhanced_detection_results.json')
        with open(summary_path, 'w') as f:
            json.dump(all_results, f, indent=2)
        
        # Save class names for future reference
        class_names_path = os.path.join(SAVE_DIR, 'class_names.txt')
        with open(class_names_path, 'w', encoding='utf-8') as f:
            for name in class_names[1:]:  # Skip BG
                f.write(f'{name}\n')
        
        # Final statistics
        total_time = time.time() - start_time
        print('\n' + '=' * 80)
        print('🎉 ENHANCED DETECTION COMPLETED!')
        print('=' * 80)
        print(f'📊 Statistics:')
        print(f'  • Total images: {len(file_names)}')
        print(f'  • Successfully processed: {processed_count}')
        print(f'  • Errors: {error_count}')
        print(f'  • Total time: {total_time:.2f}s')
        print(f'  • Average time per image: {total_time/max(processed_count,1):.2f}s')
        print(f'📁 Results saved in: {SAVE_DIR}')
        print(f'📄 Summary: enhanced_detection_results.json')
        print(f'📋 Class names saved: class_names.txt')
        print('=' * 80)
        
        logger.info('Detection process completed successfully')
        
    except Exception as e:
        logger.error(f'Critical error in main process: {e}')
        print(f'\n💥 Critical Error: {e}')
        print('Please check the logs for details.')


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print('\n\n⚠️ Process interrupted by user.')
        logger.info('Process interrupted by user')
    except Exception as e:
        logger.error(f'Unexpected error: {e}')
        print(f'\n💥 Unexpected error: {e}')
    finally:
        print('\n👋 Process finished. Press Enter to exit...')
        try:
            input()
        except:
            pass
