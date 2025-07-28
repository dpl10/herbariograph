#!/usr/bin/env python3

### SAFE AND REQUIRED IMPORTS
import getopt
import multiprocessing
import os
import shutil
import sys
import textwrap



### CONSTANTS
BANDS = 3
LABELS = ('Animal', 'Biocultural', 'Corrupted', 'Fragmentary', 'Color', 'Grayscale', 'Live', 'EM', 'RLM', 'TLM', 'Slide', 'Mixed', 'Occluded', 'Ordinary', 'Reproduction', 'Text', 'Unpressed')
MODELS = {
	'ConvNeXt-N': 'eModel/d3a3baf92aacbacf8f9a1a55a060b1c7-best/best-model.keras', ### AUCPR = 98.33%; F1 = 95.32%
	'ConvNeXt-T': 'ConvNeXt/408856b9205f788b1e4c85847785f2ef-best/soup-model.keras' ### AUCPR = 98.16%; F1 = 96.31%
}
PIXELS = 96
WRAP = shutil.get_terminal_size().columns

### OUTPUT CONSTANTS
MODEL = 0
FILE = 1
PREDICTION = 2



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
settings['batch'] = 1024
settings['cpu'] = False
settings['data'] = ''
settings['gpu'] = '0'
settings['model'] = 'ConvNeXt-N'
settings['outFile'] = ''
settings['processors'] = multiprocessing.cpu_count()



### READ OPTIONS
dataPredictError = 'Input image directory (required): -d directory | --data=directory'
outFileError = 'Output file name (required): -o file.tsv | --output=file.tsv'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'b:cd:g:hm:o:p:', ['batch=', 'cpu', 'data=', 'gpu=', 'help', 'model=', 'output=', 'processors='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-b', '--batch') and int(value) > 0:
		settings['batch'] = int(value)
	elif argument in ('-c', '--cpu'):
		settings['cpu'] = True
	elif argument in ('-d', '--data'):
		if os.path.isdir(value):
			settings['data'] = value
		else:
			eprintWrap(f"Input directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-g', '--gpu') and int(value) >= 0: ### does not test if device is valid
		settings['gpu'] = value
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to produce Herbariograph predictions from image files with TensorFlow 2.13.0.')
		eprintWrap(f"Batch size (optional; default = {settings['batch']}): -b int | --batch=int")
		eprintWrap(f"CPU only (optional; default = {settings['cpu']}): -c | --cpu")
		eprintWrap(dataPredictError)
		eprintWrap(f"Run on specified GPU (optional; default = {settings['gpu']}; CPU option overrides GPU settings): -g int | --gpu int")
		eprintWrap(f"Predictive model (optional; default = {settings['model']}): -m {'|'.join(MODELS.keys())} | --model={'|'.join(MODELS.keys())}")
		eprintWrap(outFileError)
		eprintWrap(f"Processors (optional; default = {settings['processors']}): -p int | --processors=int")
		eprint('')
		sys.exit(0)
	elif argument in ('-m', '--model') and value in MODELS:
		if os.path.isfile(MODELS[value]):
			settings['model'] = value
		else:
			eprintWrap(f"Model file for '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-o', '--output'):
		settings['outFile'] = value
	elif argument in ('-p', '--processors') and int(value) > 0:
		settings['processors'] = int(value)



### START/END
if not settings['data']:
	eprintWrap(dataPredictError)
	sys.exit(2)
elif not settings['outFile']:
	eprintWrap(outFileError)
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
availableGPUs = len(tf.config.experimental.list_physical_devices('GPU'))
if settings['cpu'] == False and availableGPUs == 0:
	eprintWrap('No GPUs are available to TensorFlow. Rerun the script with -c for CPU processing only.')
	sys.exit(2)
eprintWrap(f"TensorFlow GPUs = {availableGPUs}")
eprintWrap(f"TensorFlow {tf.version.VERSION}\n")



### READ MODEL
model = tf.keras.models.load_model(MODELS[settings['model']], compile = False)
model.compile(
	loss = tf.keras.losses.CategoricalCrossentropy(
		from_logits = True, 
		label_smoothing = 0.1
	),
	metrics = [
		tf.keras.metrics.CategoricalAccuracy(name = 'accuracy'),
		tf.keras.metrics.AUC(
			curve = 'PR',
			from_logits = True,
			multi_label = False, 
			name = 'auc',
			num_thresholds = 200, 
			summation_method = 'interpolation'
		),
		tf.keras.metrics.F1Score(
			average = 'macro',
			name = 'f1',
			threshold = None
		)
	],
	optimizer = tf.keras.optimizers.AdamW()
)
print(model.summary())



### DATASET
def parseImage(file):
	image = tf.io.decode_image(
		channels = BANDS,
		contents = tf.io.read_file(file),
		expand_animations = False
	)
	image = tf.image.resize(
		antialias = False,
		images = image,
		method = 'bilinear',
		preserve_aspect_ratio = False,
		size = (PIXELS, PIXELS)
	)
	image = tf.cast(image, dtype = tf.float32)
	return image, file

imageFiles = []
for path, subdirs, files in os.walk(settings['data']):
	for file in files:
		if file.endswith('.bmp') or file.endswith('.jpg') or file.endswith('.png'):
			imageFiles.append(os.path.join(path, file))
eprint('')
eprintWrap(f"Dataset size = {len(imageFiles):,} images.")

predictData = (
	tf.data.Dataset.from_tensor_slices(imageFiles)
	.map(
		lambda file: (parseImage(file)),
		deterministic = False,
		num_parallel_calls = tf.data.AUTOTUNE
	).batch(
		batch_size = settings['batch'],
		deterministic = False,
		drop_remainder = False,
		num_parallel_calls = tf.data.AUTOTUNE
	).prefetch(tf.data.AUTOTUNE)
)



### PREDICT AND SAVE
output = open(settings['outFile'], 'w')
print(f"MODEL\tFILE\tPREDICTION", file = output)
for k, batch in enumerate(predictData):
	images, files = batch
	eprintWrap(f"Batch {k}: {tf.shape(images)[0]} images of {tf.shape(images)[1:]}...")
	predictions = model.predict(images)
	for j, prediction in enumerate(predictions):
		print(f"{settings['model']}\t{files[j].numpy().decode('utf-8')}\t{LABELS[int(tf.argmax(prediction).numpy())]}", file = output)



### DONE
output.close()
sys.exit(0)
