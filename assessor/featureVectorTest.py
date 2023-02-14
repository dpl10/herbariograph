#!/usr/bin/env python3

import cv2
import numpy as np
import os
import sys

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
import tensorflow_hub as hub

### USER DATA
models = {} ### name => URL; name => inputShape; name => outputShape
### InceptionV3 iNaturalist data
models['InceptionV3 + iNaturalist'] = {}
models['InceptionV3 + iNaturalist']['URL'] = 'https://tfhub.dev/google/inaturalist/inception_v3/feature_vector/5'
models['InceptionV3 + iNaturalist']['inputShape'] = (299, 299)
models['InceptionV3 + iNaturalist']['outputShape'] = 2048
### EfficientnetV2B0 Imagenet21k data
models['EfficientnetV2B0 + Imagenet21k'] = {}
models['EfficientnetV2B0 + Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_ft1k_b0/feature_vector/2'
models['EfficientnetV2B0 + Imagenet21k']['inputShape'] = (224, 224)
models['EfficientnetV2B0 + Imagenet21k']['outputShape'] = 1280
### MobileNetV3 iNaturalist plus some Imagenet21k data
models['MobileNetV3 + iNaturalist + Imagenet21k'] = {}
models['MobileNetV3 + iNaturalist + Imagenet21k']['URL'] = 'https://tfhub.dev/google/cropnet/feature_vector/concat/1'
models['MobileNetV3 + iNaturalist + Imagenet21k']['inputShape'] = (224, 224)
models['MobileNetV3 + iNaturalist + Imagenet21k']['outputShape'] = 8864
### EfficientnetV2xl Imagenet21k data
models['EfficientnetV2xl + Imagenet21k'] = {}
models['EfficientnetV2xl + Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_xl/feature_vector/2'
models['EfficientnetV2xl + Imagenet21k']['inputShape'] = (512, 512)
models['EfficientnetV2xl + Imagenet21k']['outputShape'] = 1280
### EfficientnetV2l Imagenet21k data
models['EfficientnetV2l + Imagenet21k'] = {}
models['EfficientnetV2l + Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_l/feature_vector/2'
models['EfficientnetV2l + Imagenet21k']['inputShape'] = (480, 480)
models['EfficientnetV2l + Imagenet21k']['outputShape'] = 1280
### EfficientnetV2m Imagenet21k data
models['EfficientnetV2m + Imagenet21k'] = {}
models['EfficientnetV2m + Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_m/feature_vector/2'
models['EfficientnetV2m + Imagenet21k']['inputShape'] = (480, 480)
models['EfficientnetV2m + Imagenet21k']['outputShape'] = 1280
### EfficientnetV2s Imagenet21k data
models['EfficientnetV2s + Imagenet21k'] = {}
models['EfficientnetV2s + Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_s/feature_vector/2'
models['EfficientnetV2s + Imagenet21k']['inputShape'] = (384, 384)
models['EfficientnetV2s + Imagenet21k']['outputShape'] = 1280

images = {} ### class => file
images['aesthetically-pleasing-pressed-specimens'] = 'original-images/NY-pleasing/00030629.jpg'
images['biocultural-specimens'] = 'raw-dataset/biocultural-specimens/F/3b5c1300c0a201d5.jpg'
images['fragmentary-pressed-specimens'] = 'raw-dataset/fragmentary-pressed-specimens/NY/1bb5a0aad46c20a7.jpg'
images['illustrations-color'] = 'raw-dataset/illustrations-color/BR/e7e844243f62f727.jpg'
images['illustrations-gray'] = 'raw-dataset/illustrations-gray/BR/0b057cd7adba5f4a.jpg'
images['live-plants'] = 'raw-dataset/live-plants/US/000acd7685feb9db.jpg'
images['live-plants-sheets'] = 'raw-dataset/live-plants/BR/0002250515d50f2b.jpg'
images['micrographs-dissecting'] = 'raw-dataset/micrographs/P/fe2834c933522cd8.jpg'
images['micrographs-florescent'] = 'raw-dataset/micrographs/P/0c62dd0b6e169613.jpg'
images['micrographs-optical'] = 'raw-dataset/micrographs/US/a4829db440e93770.jpg'
images['micrographs-sem'] = 'raw-dataset/micrographs/US/3d628e2c3adf2a2d.jpg'
images['micrographs-tem'] = 'raw-dataset/micrographs/US/4404ebbf64d8249d.jpg'
images['microscope-slides'] = 'raw-dataset/microscope-slides/L/01dbb8da9244ec39.jpg'
images['mixed-pressed-specimens-split'] = 'raw-dataset/mixed-pressed-specimens/NY/4095408a3215492d.jpg'
images['mixed-pressed-specimens-occluded'] = 'raw-dataset/mixed-pressed-specimens/NY/370a4a81812440fa.jpg'
images['occluded-specimens-box'] = 'raw-dataset/occluded-specimens/NY/ba5b470abe31348a.jpg'
images['occluded-specimens-folder'] = 'raw-dataset/occluded-specimens/NY/35b45dcab6b06374.jpg'
images['occluded-specimens-sheet'] = 'raw-dataset/occluded-specimens/NY/0c96421ab4574924.jpg'
images['ordinary-pressed-specimens'] = 'original-images/NY-ordinary/58a6dd0334dd47d9.jpg'
images['pressed-specimen-reproductions'] = 'raw-dataset/pressed-specimen-reproductions/F/0b80fc00a4fd7a9d.jpg'
images['pressed-specimens-closeup'] = 'raw-dataset/pressed-specimens-closeup/NY/4130701feb0eaf1d.jpg'
images['spirit-preserved-specimens'] = 'raw-dataset/spirit-preserved-specimens/NY/359fc62a428727fa.jpg'
images['text-focused'] = 'raw-dataset/text-focused/NY/1cd07921d1df41cf.jpg'
images['unpressed-specimens'] = 'raw-dataset/unpressed-specimens/NY/57107a50b66cddf3.jpg'
images['xylogical-specimens'] = 'raw-dataset/xylogical-specimens/F/a2097268d95c3484.jpg'

### FUNCTIONS

### PAIRWISE COSINE DISTANCE
def cosineDistance(x, y):
	if x.shape != y.shape:
		eprint('Shapes are incompatible for cosineDistance!')
		return 0.0
	if x.ndim == 1:
		xNormalized = np.linalg.norm(x)
		yNormalized = np.linalg.norm(y)
	elif x.ndim == 2:
		xNormalized = np.linalg.norm(x, axis = 1, keepdims = True)
		yNormalized = np.linalg.norm(y, axis = 1, keepdims = True)
	else:
		eprint('Dimensions are incompatible for cosineDistance!')
		return 0.0
	similarity = np.dot(x, y.T)/(xNormalized*yNormalized) 
	distance = 1.0-similarity
	return distance

### PRINT TO STANDARD ERROR
def eprint(*args, **kwargs):
	print(*args, file = sys.stderr, **kwargs)

### EXTRACT FROM MODEL
def extractVector(file, model, shape):
	image = cv2.imread(file, flags = cv2.IMREAD_COLOR)
	image = cv2.cvtColor(image, code = cv2.COLOR_BGR2RGB)
	image = cv2.resize(image, shape) 
	image = np.array(image)/255.0
	embedding = model.predict(image[np.newaxis, ...])
	feature = np.array(embedding)
	return feature.flatten()

print('model\tcount\tminimum\tmaximum\tmean\tvariance')
for model in models.keys():
	eprint(f"Extracting feature vectors for {model}...")
	featureVectorModel = tf.keras.Sequential([hub.KerasLayer(models[model]['URL'])])
	imageClasses = []
	vectors = {}
	for imageClass, file in images.items():
		imageClasses.append(imageClass)
		vectors[imageClass] = extractVector(file, featureVectorModel, models[model]['inputShape'])
	count = 0
	M2 = 0.0
	maximum = 0.0
	mean = 0.0
	minimum = 1.0
	for k in range(0, len(imageClasses)-1):
		for j in range(k+1, len(imageClasses)):
			count += 1
			distance = cosineDistance(vectors[imageClasses[k]], vectors[imageClasses[j]])
			delta = distance-mean
			mean += delta/count
			delta2 = distance-mean
			M2 += delta*delta2
			if maximum < distance:
				maximum = distance
			if minimum > distance:
				minimum = distance
	variance = M2/(count-1)
	print(f"{model}\t{count}\t{minimum:.4f}\t{maximum:.4f}\t{mean:.4f}\t{variance:.4f}")
