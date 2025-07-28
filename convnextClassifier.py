#!/usr/bin/env python3

### SAFE IMPORTS
import getopt
import os
import shutil
import sys
import textwrap



### CONSTANT
WRAP = shutil.get_terminal_size().columns



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
settings['encoder'] = ''
settings['outFile'] = ''
settings['standard'] = False
settings['referenceModel'] = ''



### READ OPTIONS
encoderError = 'Pretrained ConvNeXt encoder (required): -e file.keras | --encoder=file.keras'
modelError = 'Randomly initialized ConvNeXt model (required): -m file.keras | --model=file.keras'
outFileError = 'Output file (required): -o file.keras | --output=file.keras'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'e:hm:o:s', ['encoder=', 'help', 'model=', 'output=', 'standard'])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-e', '--encoder'):
		if os.path.isfile(value):
			settings['encoder'] = value
		else:
			eprintWrap(f"Encoder file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to create a TensorFlow 2.13.0 ConvNeXt classification model with a pretrained encoder.')
		eprintWrap(encoderError)
		eprintWrap(modelError)
		eprintWrap(outFileError)
		eprintWrap(f"Trained model was generated in a standard way (optional; default = {settings['standard']})")
		eprint('')
		sys.exit(0)
	elif argument in ('-m', '--model'):
		if os.path.isfile(value):
			settings['referenceModel'] = value
		else:
			eprintWrap(f"Model file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-o', '--output'):
		settings['outFile'] = value
	elif argument in ('-s', '--standard'):
		settings['standard'] = True



### START/END
if not settings['encoder']:
	eprintWrap(encoderError)
	sys.exit(2)
elif not settings['referenceModel']:
	eprintWrap(modelError)
	sys.exit(2)
elif not settings['outFile']:
	eprintWrap(outFileError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")



### DISABLE GPU, THEN IMPORT TENSORFLOW
os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'
import tensorflow as tf
eprintWrap(f"TensorFlow {tf.version.VERSION}\n")



### CLASSIFIER MODEL
def classifier():
	referenceModel = tf.keras.models.load_model(settings['referenceModel'], compile = False)
	trainedModel = tf.keras.models.load_model(settings['encoder'], compile = False)
	reimaginedModel = tf.keras.models.model_from_json(referenceModel.to_json())
	for layer in reimaginedModel.layers:
		try:
			if layer.name == 'gap_resolve_dense' and not settings['standard']:
				layer.set_weights(trainedModel.get_layer(name = 'hidden_output').get_weights())
				layer.trainable = True
			elif layer.name in ('normalization', 'output_gap', 'output_layerNormalization', 'gap_resolve_dense', 'output_dense'):
				layer.set_weights(referenceModel.get_layer(name = layer.name).get_weights())
				layer.trainable = True
			else:
				layer.set_weights(trainedModel.get_layer(name = layer.name).get_weights())
				layer.trainable = False
		except:
			eprintWrap(f"Could not transfer weights for layer {layer.name}")
	modelTruncated = tf.keras.Model(inputs = reimaginedModel.input, outputs = reimaginedModel.layers[-1].output)
	return modelTruncated



### OUTPUT
model = classifier()
eprint(model.summary())
model.save(filepath = settings['outFile'], save_format = 'keras')
sys.exit(0)
