#!/usr/bin/env python3

### SAFE IMPORTS
import getopt
import os
import random
import re
import shutil
import sys
import textwrap



### CONSTANTS
ACTIVATIONS = ('elu', 'gelu', 'relu', 'selu', 'swish')
BLOCKS = re.compile('^[0-9]+:[0-9]+:[0-9]+:[0-9]+$')
CHANNELS = -1
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
settings['activation'] = 'gelu'
settings['bands'] = 3
settings['convNEXTblocks'] = [3, 3, 9, 3]
settings['depthwiseRemove'] = False
settings['expansionRatio'] = 4
settings['filters'] = 96
settings['inputSize'] = 256
settings['layerScale'] = False
settings['maxpoolReduce'] = False
settings['noiseInjection'] = False
settings['outFile'] = ''
settings['outputArray'] = None
settings['outputPolish'] = 0
settings['randomSeed'] = 123456789
settings['squeezeExciteChannels'] = False
settings['squeezeExciteSpatial'] = False



### OTHER SETTINGS
settings['dformat'] = 'channels_last'
settings['epsilon'] = 1e-5
settings['initializer'] = 'glorot_uniform'
# settings['kernel'] = [(7, 7)]*4 ### original, but slightly less performant
settings['kernel'] = [(5, 5)]*4
settings['layerScaleEpsilon'] = 1.0
settings['randomMax'] = 2**32 ### 64 is unsafe (53 is max safe)
settings['randomMin'] = 0
settings['recodeNoise'] = 0.10
settings['seRatio'] = 4
settings['weightDecay'] = 1e-4



### READ OPTIONS
arrayError = 'Number of elements in the output array (required): -a int | --array=int'
outFileError = 'Output file (required): -o file.keras | --output=file.keras'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'a:b:cde:f:ghi:lmn:o:p:r:sx:', ['array=', 'bands=', 'channel', 'depthwise', 'expansion=', 'function=', 'gaussian', 'help', 'input=', 'layer', 'maxpool', 'next=', 'output=', 'polish=' 'random=', 'spatial', 'filters='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-a', '--array') and int(value) > 0:
		settings['outputArray'] = int(value)
	elif argument in ('-b', '--bands') and int(value) > 0:
		settings['bands'] = int(value)
	elif argument in ('-c', '--channel'):
		settings['squeezeExciteChannels'] = True
	elif argument in ('-d', '--depthwise'):
		settings['depthwiseRemove'] = True
	elif argument in ('-e', '--expansion') and int(value) > 0:
		settings['expansionRatio'] = int(value)
	elif argument in ('-f', '--function') and value in ACTIVATIONS:
		settings['activation'] = value
	elif argument in ('-g', '--gaussian'):
		settings['noiseInjection'] = True
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to create a TensorFlow 2.13.0 ConvNeXt model (arXiv:2201.03545).')
		eprintWrap(arrayError)
		eprintWrap(f"Input image bands (optional; default = {settings['bands']}): -b int | --bands=int")
		eprintWrap(f"Insert squeeze and excite modules (i.e. channel attention; arXiv:1709.01507; optional; default = {settings['squeezeExciteChannels']}): -c | --channel")
		eprintWrap(f"Replace depth-wise convolution in blocks with regular convolution (optional; default = {settings['depthwiseRemove']}): -d | --depthwise")
		eprintWrap(f"ConvNeXt block expansion ratio (optional; default = {settings['expansionRatio']}): -e int | --expansion int")
		eprintWrap(f"Internal activation function (optional; default = {settings['activation']}): -f {'|'.join(ACTIVATIONS)} | --function={'|'.join(ACTIVATIONS)}")
		eprintWrap(f"Insert Gaussian noise injection (optional; default = {settings['noiseInjection']}): -g | --gaussian")
		eprintWrap(f"Input image size (optional; default = {settings['inputSize']}): -i int | --input=int")
		eprintWrap(f"Use LayerScale in ConvNext (V1) block (optional; default = {settings['layerScale']}): -l | --layer")
		eprintWrap(f"Use maxpool+conv in place of the original down sampler (optional; default = {settings['maxpoolReduce']}): -m | --maxpool")
		eprintWrap(f"ConvNeXt blocks (optional; default = {':'.join([str(x) for x in settings['convNEXTblocks']])}; T = 3:3:9:3; S|B|L|XL = 3:3:27:3): -n int:int:int:int | --next=int:int:int:int")
		eprintWrap(outFileError)
		eprintWrap(f"Number of channels used for output polishing (optional; default = {settings['outputPolish']}): -p int | --polish=int")
		eprintWrap(f"Random seed (optional; default = {settings['randomSeed']}): -r int | --random=int")
		eprintWrap(f"Insert squeeze and excite modules (i.e. spatial attention; arXiv:1803.02579; optional; default = {settings['squeezeExciteSpatial']}): -s | --spatial")
		eprintWrap(f"Number of ConvNeXt expansion filters (optional; default = {settings['filters']}; T|S = 96; B = 128; L = 192; XL = 256): -x int | --filters=int")
		eprint('')
		sys.exit(0)
	elif argument in ('-i', '--input') and int(value) > 0:
		settings['inputSize'] = int(value)
	elif argument in ('-l', '--layer'):
		settings['layerScale'] = True
	elif argument in ('-m', '--maxpool'):
		settings['maxpoolReduce'] = True
	elif argument in ('-n', '--next') and re.search(BLOCKS, value):
		settings['convNEXTblocks'] = [int(x) for x in value.split(':')]
	elif argument in ('-o', '--output'):
		settings['outFile'] = value
	elif argument in ('-p', '--polish') and int(value):
		settings['outputPolish'] = int(value)
	elif argument in ('-r', '--random') and int(value) >= settings['randomMin'] and int(value) <= settings['randomMax']:
		settings['randomSeed'] = int(value)
	elif argument in ('-s', '--spatial'):
		settings['squeezeExciteSpatial'] = True
	elif argument in ('-x', '--filters') and int(value) > 0:
		settings['filters'] = int(value)



### START/END
if not settings['outputArray']:
	eprintWrap(arrayError)
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
from LayerScale import LayerScale
eprintWrap(f"TensorFlow {tf.version.VERSION}\n")



### INIT
random.seed(settings['randomSeed'])
tf.random.set_seed(random.randint(settings['randomMin'], settings['randomMax']))
settings['regularizer'] = tf.keras.regularizers.L2(
	l2 = settings['weightDecay']
)



### CONV2D
def conv2D(x, activation, dilation, filters, groups, kernel, name, padding, strides):
	return tf.keras.layers.Conv2D(
		activation = activation,
		activity_regularizer = None,
		bias_constraint = None,
		bias_initializer = None,
		bias_regularizer = None,
		data_format = settings['dformat'],
		dilation_rate = dilation,
		filters = filters,
		groups = groups,
		kernel_constraint = None,
		kernel_initializer = settings['initializer'],
		kernel_regularizer = settings['regularizer'],
		kernel_size = kernel,
		name = f"{name}_conv2D",
		padding = padding,
		strides = strides,
		use_bias = False
	)(x)

### CONVNEXT BLOCK (ARXIV:2201.03545)
def convNeXtBlock(convnext, kernel, name):
	filters = convnext.shape[CHANNELS]
	skipConnection = convnext
	convnext = xconv2D(
		x = convnext,
		activation = None,
		dilation = 1,
		filters = filters,
		groups = 1,
		kernel = kernel,
		name = f"{name}_{'x'.join([str(x) for x in kernel])}",
		padding = 'same',
		strides = 1
	)
	convnext = normalize(convnext, f"{name}")
	convnext = conv2D(
		x = convnext,
		activation = settings['activation'],
		dilation = 1,
		filters = filters*settings['expansionRatio'],
		groups = 1,
		kernel = (1, 1),
		name = f"{name}_expand",
		padding = 'same',
		strides = 1
	)
	convnext = conv2D(
		x = convnext,
		activation = None,
		dilation = 1,
		filters = filters,
		groups = 1,
		kernel = (1, 1),
		name = f"{name}_smooth",
		padding = 'same',
		strides = 1
	)
	if settings['layerScale']:
		convnext = LayerScale(
			epsilon = settings['layerScaleEpsilon'],
			name = f"{name}_layerScale"
		)(convnext)
	if settings['noiseInjection']:
		convnext = tf.keras.layers.GaussianNoise( ### active only in training
			seed = random.randint(settings['randomMin'], settings['randomMax']),
			stddev = settings['recodeNoise']
		)(convnext)
	convnext += skipConnection
	return convnext

### CONVNEXT (ARXIV:2201.03545)
def convNeXt():
	input = tf.keras.layers.Input(
		(None, None, settings['bands']),
		name = 'input'
	)
	convnext = input
	# convnext = tf.keras.layers.RandomCrop( ### active in both training and inference: random in training; in inference rescaled to preserve the shorter side and center cropped
	# 	height = settings['inputSize'],
	# 	seed = random.randint(settings['randomMin'], settings['randomMax']),
	# 	width = settings['inputSize']
	# )(convnext)
	convnext = tf.keras.layers.Rescaling(
		name = 'rescale',
		offset = -1,
		scale = 1.0/127.5 
	)(convnext)
	convnext = conv2D(
		x = convnext,
		activation = None,
		dilation = 1,
		filters = settings['filters'],
		groups = 1,
		kernel = (4, 4),
		name = 'convNeXt0_downSample',
		# padding = 'same',
		padding = 'valid', ### original? but slightly less performant?
		strides = 4
	)
	convnext = normalize(convnext, 'convNeXt0_downSample')
	for k, blocks in enumerate(settings['convNEXTblocks']):
		if k > 0:
			convnext = downSample(
				convnext = convnext, 
				filters = convnext.shape[CHANNELS]*2, 
				kernel = 2,
				name = f"convNeXt{k}"
			)
			convnext = squeezeExcite(convnext, f"convNeXt{k}")
		for j in range(0, blocks):
			convnext = convNeXtBlock(
				convnext = convnext, 
				kernel = settings['kernel'][k],
				name = f"convNeXt{k}_block{j}"
			)
	convnext = gap(
		x = convnext, 
		flatten = True,
		name = 'output'
	)
	convnext = normalize(convnext, 'output')
	if settings['outputPolish'] > 0:
		convnext = dense(
			x = convnext, 
			activation = settings['activation'], 
			bias = False,
			name = 'gap_resolve', 
			units = settings['outputPolish']
		)
	output = dense(
		x = convnext, 
		activation = None, 
		bias = True, 
		name = 'output', 
		units = settings['outputArray']
	)
	return tf.keras.Model(inputs = input, outputs = output)

### DENSE
def dense(x, activation, bias, name, units, zeros = True):
	return tf.keras.layers.Dense(
		activation = activation,
		activity_regularizer = None,
		bias_constraint = None,
		bias_initializer = 'zeros' if zeros else 'ones',
		bias_regularizer = None,
		kernel_constraint = None,
		kernel_initializer = settings['initializer'],
		kernel_regularizer = None,
		name = f"{name}_dense",
		units = units,
		use_bias = bias
	)(x)

### DOWNSAMPLE
def downSample(convnext, filters, kernel, name):
	if settings['maxpoolReduce']:
		convnext = tf.keras.layers.MaxPool2D(
			name = f"{name}_maxpool2D",
			padding = 'same',
			pool_size = (2, 2),
			strides = 2
		)(convnext)
		convnext = normalize(convnext, f"{name}_downSample")
		convnext = conv2D(
			x = convnext,
			activation = None,
			dilation = 1,
			filters = filters,
			groups = 1,
			kernel = (1, 1),
			name = f"{name}_expandConvNeXt",
			padding = 'same',
			strides = 1
		)
	else:
		convnext = normalize(convnext, f"{name}_downSample")
		convnext = conv2D(
			x = convnext,
			activation = None,
			dilation = 1,
			filters = filters,
			groups = 1,
			kernel = (kernel, kernel),
			name = f"{name}_downSample",
			padding = 'same',
			strides = kernel
		)
	return convnext

### DCONV2D
def dconv2D(x, activation, dilation, kernel, name, padding, strides):
	return tf.keras.layers.DepthwiseConv2D(
		activation = activation,
		activity_regularizer = None,
		bias_constraint = None,
		bias_initializer = None,
		bias_regularizer = None,
		data_format = settings['dformat'],
		depth_multiplier = 1,
		depthwise_constraint = None,
		depthwise_initializer = settings['initializer'],
		depthwise_regularizer = settings['regularizer'],
		dilation_rate = dilation,
		kernel_size = kernel,
		name = f"{name}_dconv2D",
		padding = padding,
		strides = strides,
		use_bias = False,
	)(x)

### GLOBAL AVERAGE POOLING
def gap(x, flatten, name):
	return tf.keras.layers.GlobalAveragePooling2D(
		data_format = settings['dformat'], 
		keepdims = not flatten,
		name = f"{name}_gap", 
	)(x)

### LAYER NORMALIZATION
def normalize(x, name):
	return tf.keras.layers.LayerNormalization(
		axis = -1,
		beta_constraint = None,
		beta_initializer = 'zeros',
		beta_regularizer = None,
		center = True,
		epsilon = settings['epsilon'],
		gamma_constraint = None,
		gamma_initializer = 'ones',
		gamma_regularizer = None,
		name = f"{name}_layerNormalization",
		scale = True
	)(x)

### SQUEEZE AND EXCITE
def squeezeExcite(x, name):
	if settings['squeezeExciteChannels'] and settings['squeezeExciteSpatial']:
		skipConnection = x
		x = squeezeExciteSpatial(x, name)
		x += skipConnection
		x = squeezeExciteChannels(x, name)
		x += skipConnection
		return x
	elif settings['squeezeExciteChannels']:
		return squeezeExciteChannels(x, name)
	elif settings['squeezeExciteSpatial']:
		return squeezeExciteSpatial(x, name)
	else:
		return x

### SQUEEZE AND EXCITE CHANNELS (ARXIV:1709.01507)
def squeezeExciteChannels(x, name):
	units = x.shape[CHANNELS]
	se = gap(
		x = x, 
		flatten = False,
		name = f"{name}_squeezeExcite"
	)
	se = dense(
		x = se, 
		activation = settings['activation'], 
		bias = False, 
		name = f"{name}_squeeze", 
		units = units//settings['seRatio']
	)
	se = dense(
		x = se, 
		activation = 'sigmoid',
		bias = False, 
		name = f"{name}_excite", 
		units = units
	)
	x *= se
	return x

### SQUEEZE AND EXCITE SPATIAL (ARXIV:1709.01507)
def squeezeExciteSpatial(x, name):
	se = conv2D(
		x = x,
		activation = 'sigmoid',
		dilation = 1,
		filters = 1,
		groups = 1,
		kernel = (1, 1),
		name = f"{name}_fuse",
		padding = 'same',
		strides = 1
	)
	x *= se
	return x

### CONV2D WRAPPER
def xconv2D(x, activation, dilation, filters, groups, kernel, name, padding, strides):
	if settings['depthwiseRemove']:
		return conv2D(x, activation, dilation, filters, groups, kernel, name, padding, strides)
	else:
		return dconv2D(x, activation, dilation, kernel, name, padding, strides)



### OUTPUT
model = convNeXt()
eprint(model.summary())
model.save(filepath = settings['outFile'], save_format = 'keras')
sys.exit(0)
