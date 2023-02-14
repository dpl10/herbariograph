#!/usr/bin/env python3

### SAFE AND REQUIRED IMPORTS
import cv2
import getopt
import numpy as np
import os
import re
import shutil
import sys
import textwrap



### CONSTANTS
MODELS = {} ### name => URL; name => inputShape; name => outputShape
### EfficientnetV2B0 Imagenet21k data
MODELS['EfficientnetV2B0+Imagenet21k'] = {}
MODELS['EfficientnetV2B0+Imagenet21k']['URL'] = 'https://tfhub.dev/google/imagenet/efficientnet_v2_imagenet21k_ft1k_b0/feature_vector/2'
MODELS['EfficientnetV2B0+Imagenet21k']['inputShape'] = (224, 224)
MODELS['EfficientnetV2B0+Imagenet21k']['outputShape'] = 1280
### MobileNetV3 iNaturalist plus some Imagenet21k data
MODELS['MobileNetV3+iNaturalist+Imagenet21k'] = {}
MODELS['MobileNetV3+iNaturalist+Imagenet21k']['URL'] = 'https://tfhub.dev/google/cropnet/feature_vector/concat/1'
MODELS['MobileNetV3+iNaturalist+Imagenet21k']['inputShape'] = (224, 224)
MODELS['MobileNetV3+iNaturalist+Imagenet21k']['outputShape'] = 1280 ### webpage says 8864... 
MODELSOPTIONS = '|'.join(MODELS.keys())
WRAP = shutil.get_terminal_size().columns


### GENERAL FUNCTIONS

### PRINT TO STANDARD ERROR
def eprint(*args, **kwargs):
	print(*args, file = sys.stderr, **kwargs)

### WRAP TEXT
def eprintWrap(string, columns = WRAP):
	eprint(wrap(string, columns))

def wrap(string, columns = WRAP):
	return '\n'.join(textwrap.wrap(string, columns))



### USER SETTINGS
settings = {}
settings['append'] = False
settings['cpu'] = False
settings['gpu'] = '0'
settings['inputDirectory'] = ''
settings['label'] = ''
settings['model'] = ''
settings['output'] = ''
settings['predict'] = 128 



### READ OPTIONS
inputError = 'Input directory of images (required): -i directory | --input=directory'
labelError = 'Class label (required): -l name | --label=name'
modelError = f"Feature vector model (required): -m {MODELSOPTIONS} | --model={MODELSOPTIONS}"
outputError = 'Output file name (required): -o file.tsv | --output=file.tsv'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'acg:hi:l:m:o:p:', ['append', 'cpu', 'gpu=', 'help', 'input=', 'label=', 'model=', 'output=', 'predict='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-a', '--append'):
		settings['append'] = True
	elif argument in ('-c', '--cpu'):
		settings['cpu'] = True
	elif argument in ('-g', '--gpu') and int(value) >= 0: ### does not test if device is valid
		settings['gpu'] = value
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to extract feature vectors from pretrained models with TensorFlow 2.9.3.')
		eprintWrap(f"Append output file (optional; default = {settings['append']}): -a | --append")
		eprintWrap(f"CPU only (optional; default = {not settings['cpu']}): -c | --cpu")
		eprintWrap(f"Run on specified GPU (optional; default = {settings['gpu']}; CPU option overrides GPU settings): -g int | --gpu=int")
		eprintWrap(inputError)
		eprintWrap(labelError)
		eprintWrap(modelError)
		eprintWrap(f"Number of images to output predictions for (optional; default = {settings['predict']}): -p int | --predict=int")
		eprintWrap(outputError)
		eprint('')
		sys.exit(0)
	elif argument in ('-i', '--input'):
		if os.path.isdir(value):
			settings['inputDirectory'] = value
		else:
			eprintWrap(f"Input image directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-l', '--label'):
		settings['label'] = value
	elif argument in ('-m', '--model') and value in MODELS:
		settings['model'] = value
	elif argument in ('-o', '--output'):
		settings['output'] = value
	elif argument in ('-p', '--predict') and int(value) > 0:
		settings['predict'] = int(value)



### START/END
if not settings['inputDirectory']:
	eprintWrap(inputError)
	sys.exit(2)
elif not settings['label']:
	eprintWrap(labelError)
	sys.exit(2)
elif not settings['model'] :
	eprintWrap(modelError)
	sys.exit(2)
elif not settings['output'] :
	eprintWrap(outputError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")



### DISABLE OR SET GPU, THEN IMPORT TENSORFLOW
if settings['cpu'] == True:
	os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
else:
	os.environ['CUDA_VISIBLE_DEVICES'] = settings['gpu']
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
import tensorflow_hub as hub
availableGPUs = len(tf.config.experimental.list_physical_devices('GPU'))
if settings['cpu'] == False and availableGPUs == 0:
	eprintWrap('No GPUs are available to TensorFlow. Rerun the script with -c for CPU processing only.')
	sys.exit(2)
eprintWrap(f"TensorFlow GPUs = {availableGPUs}")
eprintWrap(f"TensorFlow {tf.version.VERSION}\n")



### FORMAT VECTOR
def formatVector(file, model, shape):
	vector = extractVector(file, model, shape).tolist()
	strings = []
	for value in vector:
		strings.append(f"{value:.7f}")
	return '\t'.join(strings)



### EXTRACT FROM MODEL
def extractVector(file, model, shape):
	image = cv2.imread(file, flags = cv2.IMREAD_COLOR)
	image = cv2.cvtColor(image, code = cv2.COLOR_BGR2RGB)
	image = cv2.resize(image, shape) 
	image = np.array(image)/255.0
	embedding = model.predict(image[np.newaxis, ...])
	feature = np.array(embedding).flatten()
	return feature



### FIND AND EXTRACT FROM FILES
analyzed = 0
featureVectorModel = tf.keras.Sequential([hub.KerasLayer(MODELS[settings['model']]['URL'])])
output = open(settings['output'], 'a' if settings['append'] else 'w')
padding = len(str(MODELS[settings['model']]['outputShape']))
vectors = '\tv'.join(f"{x:0{padding}}" for x in range(0, MODELS[settings['model']]['outputShape']))
if not settings['append']:
	print(f"class\tmodel\tfile\tv{vectors}", file = output)
for path, subdirs, files in os.walk(settings['inputDirectory']):
	for file in files:
		if file.endswith('.jpg'):
			f = os.path.join(path, file)
			print(f"{settings['label']}\t{settings['model']}\t{f}\t{formatVector(f, featureVectorModel, MODELS[settings['model']]['inputShape'])}", file = output)
			analyzed += 1
			if analyzed > settings['predict']:
				break
	if analyzed > settings['predict']:
		break
output.close()