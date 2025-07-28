#!/usr/bin/env python3

### SAFE AND REQUIRED IMPORTS
import datetime
import getopt
import hashlib
import json
import multiprocessing
import numpy as np
import os
import random
import shutil
import sys
import textwrap



### CONSTANTS
EPSILON = 1e-07
TOP = 3
WRAP = shutil.get_terminal_size().columns

### LOG FILE CONSTANTS
ITERATION = 0
SETTINGS = 1
F1 = 2



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
settings['cpu'] = False
settings['dataTrain'] = ''
settings['dataValidate'] = ''
settings['epochs'] = 32
settings['gpu'] = '0'
settings['imageSize'] = 224
settings['modelStudent'] = ''
settings['modelTeacher'] = ''
settings['optimalSettings'] = ''
settings['outputArray'] = None
settings['outputDirectory'] = ''
settings['processors'] = multiprocessing.cpu_count()
settings['studentSize'] = 64
settings['randomSeed'] = 123456789



### OTHER SETTINGS
settings['analysisTime'] = datetime.datetime.now(datetime.timezone.utc).isoformat()
settings['beta1'] = 0.9 ### AdamW
settings['beta2'] = 0.999 ### AdamW
settings['channels'] = 3
settings['clrInitial'] = 4 ### clr; try 3
settings['ema_momentum'] = 0.99 ### AdamW
settings['patience'] = 16
settings['randomMax'] = 2**32 ### 64 is unsafe (53 is max safe)
settings['randomMin'] = 0



### READ OPTIONS
arrayError = 'Number of elements in the output array (required): -a int | --array=int'
dataTrainError = 'Input train data (required): -t file.tfr | --train file.tfr'
dataValidateError = 'Input validation data (required): -v file.tfr | --validate file.tfr'
modelStudentError = 'Input student model file (required): -s file.keras | --student=file.keras'
modelTeacherError = 'Input teacher model directory (required): -m dir | --model=dir'
optimalSettingsError = 'Input settings from optimizeImagesR.py (required): -l optimization-log.tsv | --log=optimization-log.tsv'
outputDirectoryError = 'Output directory (required): -o directory | --output=directory'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'a:ce:g:hi:l:m:o:p:r:S:s:t:v:', ['array=', 'cpu', 'epochs=', 'gpu=', 'help', 'image=', 'log=', 'model=', 'output=', 'processors=', 'random=', 'size=', 'student=', 'train=', 'validate='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-a', '--array') and int(value) > 0:
		settings['outputArray'] = int(value)
	elif argument in ('-c', '--cpu'):
		settings['cpu'] = True
	elif argument in ('-e', '--epochs') and int(value) > 0:
		settings['epochs'] = int(value)
	elif argument in ('-g', '--gpu') and int(value) >= 0: ### does not test if device is valid
		settings['gpu'] = value
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to distill models using optimized hyperparameters with images from .tfr files with TensorFlow 2.13.0.')
		eprintWrap(arrayError)
		eprintWrap(f"CPU only (optional; default = {not settings['cpu']}): -c | --cpu")
		eprintWrap(f"Number of epochs per training (optional; default = {settings['epochs']}): -e int | --epochs=int")
		eprintWrap(f"Run on specified GPU (optional; default = {settings['gpu']}; CPU option overrides GPU settings): -g int | --gpu=int")
		eprintWrap(f"Input image size (optional; default = {settings['imageSize']}): -i int | --image=int")
		eprintWrap(modelTeacherError)
		eprintWrap(outputDirectoryError)
		eprintWrap(f"Processors (optional; default = {settings['processors']}): -p int | --processors=int")
		eprintWrap(f"Random seed (optional; default = {settings['randomSeed']}): -r int | --random=int")
		eprintWrap(f"Student input size (optional; default = {settings['studentSize']}): -S int | --size=int")
		eprintWrap(modelStudentError)
		eprintWrap(dataTrainError)
		eprintWrap(dataValidateError)
		eprint('')
		sys.exit(0)
	elif argument in ('-i', '--image') and int(value) > 0:
		settings['imageSize'] = int(value)
	elif argument in ('-l', '--log'):
		if os.path.isdir(value):
			settings['optimalSettings'] = value
		else:
			eprintWrap(f"Input settings file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-m', '--model'):
		if os.path.isdir(value):
			settings['modelTeacher'] = value
		else:
			eprintWrap(f"Teacher model directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-o', '--output'):
		if os.path.isdir(value):
			settings['outputDirectory'] = value
		else:
			eprintWrap(f"Model output directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-p', '--processors') and int(value) > 0:
		settings['processors'] = int(value)
	elif argument in ('-r', '--random') and int(value) >= settings['randomMin'] and int(value) <= settings['randomMax']:
		settings['randomSeed'] = int(value)
	elif argument in ('-S', '--size') and int(value) > 0:
		settings['studentSize'] = int(value)
	elif argument in ('-s', '--student'):
		if os.path.isfile(value):
			settings['modelStudent'] = value
		else:
			eprintWrap(f"Student model file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-t', '--train'):
		if os.path.isfile(value):
			settings['dataTrain'] = value
		else:
			eprintWrap(f"Input train file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-v', '--validate'):
		if os.path.isfile(value):
			settings['dataValidate'] = value
		else:
			eprintWrap(f"Input validation file '{value}' does not exist!")
			sys.exit(2)



### START/END
if not settings['outputArray']:
	eprintWrap(arrayError)
	sys.exit(2)
elif not len(settings['dataValidate']):
	eprintWrap(dataValidateError)
	sys.exit(2)
elif not settings['dataTrain']:
	eprintWrap(dataTrainError)
	sys.exit(2)
elif not settings['modelStudent']:
	eprintWrap(modelStudentError)
	sys.exit(2)
elif not settings['modelTeacher']:
	eprintWrap(modelTeacherError)
	sys.exit(2)
elif not settings['optimalSettings']:
	eprintWrap(optimalSettingsError)
	sys.exit(2)
elif not settings['outputDirectory']:
	eprintWrap(outputDirectoryError)
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



### DATASET FUNCTIONS
def augmentApply(image, config, function, probability = 1.0): ### modified from https://github.com/hirune924/imgaug-tf
	apply = tf.math.less(tf.random.uniform([], 0.0, 1.0, dtype = tf.float32), probability)
	image = tf.cond(apply, lambda: function(image, config), lambda: image)
	return image

def augmentGaussianNoise(image, config): ### https://github.com/Ximilar-com/tf-image
	sd = tf.random.uniform([], 0.0, config['GaussianNoiseSDmax'])
	noise = 255.0*tf.random.normal(shape = tf.shape(image), mean = 0.0, stddev = sd)
	image += noise
	image = tf.clip_by_value(image, 0.0, 255.0)
	return image

def augmentLeftRight(image, config):
	image = tf.image.flip_left_right(image)
	return image

def augmentRotateOne(image, config):
	image = tf.image.rot90(image, k = 1)
	return image

def augmentRotateTwo(image, config):
	image = tf.image.rot90(image, k = 2)
	return image

def augmentRotateThree(image, config):
	image = tf.image.rot90(image, k = 3)
	return image

def augmentShearX(image, config): ### https://github.com/hirune924/imgaug-tf
	level = tf.random.uniform([], -1.0*config['shearXproportion'], config['shearXproportion'], dtype = tf.float32)
	image = tf.expand_dims(image, 0)
	image = tf.raw_ops.ImageProjectiveTransformV3(
		fill_mode = 'CONSTANT',
		fill_value = 0.0,
		images = image,
		interpolation = 'BILINEAR',
		output_shape = (settings['imageSize'], settings['imageSize']),
		transforms = [[1.0, level, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]]
	)
	image = tf.squeeze(image)
	image = tf.reshape(image, (settings['imageSize'], settings['imageSize'], settings['channels'])) ### kluge
	return image

def augmentShearY(image, config): ### https://github.com/hirune924/imgaug-tf
	level = tf.random.uniform([], -1.0*config['shearYproportion'], config['shearYproportion'], dtype = tf.float32)
	image = tf.expand_dims(image, 0)
	image = tf.raw_ops.ImageProjectiveTransformV3(
		fill_mode = 'CONSTANT',
		fill_value = 0.0,
		images = image,
		interpolation = 'BILINEAR',
		output_shape = (settings['imageSize'], settings['imageSize']),
		transforms = [[1.0, 0.0, 0.0, level, 1.0, 0.0, 0.0, 0.0]]
	)
	image = tf.squeeze(image)
	image = tf.reshape(image, (settings['imageSize'], settings['imageSize'], settings['channels'])) ### kluge
	return image

def augmentUpDown(image, config):
	image = tf.image.flip_up_down(image)
	return image

def batchMix(images, labels, batch, probability = 1.0): ### based on https://www.kaggle.com/code/yihdarshieh/batch-implementation-of-more-data-augmentations/notebook?scriptVersionId=29767726 and https://www.kaggle.com/code/cdeotte/cutmix-and-mixup-on-gpu-tpu
	mixup = tf.cast(tf.random.uniform([batch], 0.0, 1.0) <= probability, tf.int32)
	mix = tf.random.uniform([batch], 0.0, 1.0)*tf.cast(mixup, tf.float32) ### beta distribution with alpha = 1.0
	new = tf.cast(tf.random.uniform([batch], 0.0, batch), tf.int32)
	mixupImages = (1-mix)[:, tf.newaxis, tf.newaxis, tf.newaxis] * images + mix[:, tf.newaxis, tf.newaxis, tf.newaxis] * tf.gather(images, new)
	mixupLabels = (1-mix)[:, tf.newaxis] * labels + mix[:, tf.newaxis] * tf.gather(labels, new)
	return mixupImages, mixupLabels

def batchRandomResizedCrop(images, labels, batch, config):
	randomRatios = tf.exp(tf.random.uniform((batch, ), tf.math.log(config['resizeRatioLow']), tf.math.log(config['resizeRatioHigh']), dtype = tf.float32))
	randomScales = tf.random.uniform((batch, ), config['resizeScaleLow'], config['resizeScaleHigh'], dtype = tf.float32)
	cropHeights = tf.clip_by_value(tf.sqrt(randomScales/randomRatios), 0.0, 1.0)
	cropWidths = tf.clip_by_value(tf.sqrt(randomScales*randomRatios), 0.0, 1.0)
	heightOffsets = tf.random.uniform((batch, ), 0.0, 1.0-cropHeights, dtype = tf.float32)
	widthOffsets = tf.random.uniform((batch, ), 0.0, 1.0-cropWidths, dtype = tf.float32)
	boundingBoxes = tf.stack([heightOffsets, widthOffsets, heightOffsets+cropHeights, widthOffsets+cropWidths], axis = 1)
	images = tf.image.crop_and_resize(
		box_indices = tf.range(batch, dtype = tf.int32),
		boxes = boundingBoxes,
		crop_size = (settings['imageSize'], settings['imageSize']),
		extrapolation_value = 0.0,
		image = images,
		method = 'bilinear'
	)
	return images, labels

def decodeTFR(record):
	feature = {
		'category': tf.io.FixedLenFeature([], tf.int64),
		'image': tf.io.FixedLenFeature([], tf.string)
	}
	record = tf.io.parse_single_example(record, feature)
	image = tf.cast(tf.io.decode_jpeg(
		channels = settings['channels'],
		contents = record['image']
	), tf.float32)
	# image = tf.image.resize(
	# 	antialias = False,
	# 	images = image,
	# 	method = 'bilinear',
	# 	preserve_aspect_ratio = False,
	# 	size = (settings['imageSize'], settings['imageSize'])
	# )
	record['category'] = tf.one_hot(
		depth = settings['outputArray'],
		indices = record['category']
	)
	return image, record['category']

def unifiedBatchAugmenter(images, labels, config):
	batch = 2**config['batch']
	images, labels = batchRandomResizedCrop(images, labels, batch, config)
	images, labels = batchMix(images, labels, batch)
	return images, labels

def unifiedSingleAugmenter(image, label, config):
	### shape, not color
	image = augmentApply(image, config, augmentLeftRight, config['leftRight'])
	image = augmentApply(image, config, augmentRotateOne, config['rotateOne'])
	image = augmentApply(image, config, augmentRotateThree, config['rotateThree'])
	image = augmentApply(image, config, augmentRotateTwo, config['rotateTwo'])
	image = augmentApply(image, config, augmentShearX, config['shearX'])
	image = augmentApply(image, config, augmentShearY, config['shearY'])
	image = augmentApply(image, config, augmentUpDown, config['upDown'])
	### color
	image = augmentApply(image, config, augmentGaussianNoise, config['GaussianNoise'])
	return image, label

### MAKE DATASETS 
def dataInit(config):
	batch = 2**config['batch']
	trainData = (
		tf.data.TFRecordDataset(settings['dataTrain'])
		.map(
			lambda x: (decodeTFR(x)),
			deterministic = False,
			num_parallel_calls = tf.data.AUTOTUNE
		).map(
			lambda x, y: (unifiedSingleAugmenter(x, y, config)),
			deterministic = False,
			num_parallel_calls = tf.data.AUTOTUNE
		).shuffle(
			buffer_size = batch*48,
			reshuffle_each_iteration = True
		).batch(
			batch_size = batch,
			deterministic = False,
			drop_remainder = True,
			num_parallel_calls = tf.data.AUTOTUNE
		).map(
			lambda x, y: (unifiedBatchAugmenter(x, y, config)),
			deterministic = False,
			num_parallel_calls = tf.data.AUTOTUNE
		).prefetch(tf.data.AUTOTUNE)
	)
	validationData = (
		tf.data.TFRecordDataset(settings['dataValidate'])
		.map(
			lambda x: (decodeTFR(x)),
			deterministic = False,
			num_parallel_calls = tf.data.AUTOTUNE
		).batch(
			batch_size = batch,
			deterministic = False,
			drop_remainder = False,
			num_parallel_calls = tf.data.AUTOTUNE
		).prefetch(tf.data.AUTOTUNE)
	)
	return trainData, validationData



### TRAINING CLASSES AND FUNCTION
class CyclicalLearningRate(tf.keras.optimizers.schedules.LearningRateSchedule): ### Smith (2015; https://arxiv.org/abs/1506.01186) based on https://github.com/tensorflow/addons/blob/master/tensorflow_addons/optimizers/cyclical_learning_rate.py
	def __init__(self, initial_learning_rate, maximal_learning_rate, step_size, scale_fn, scale_mode = 'cycle', name = 'CyclicalLearningRate'):
		super().__init__()
		self.initial_learning_rate = initial_learning_rate
		self.maximal_learning_rate = maximal_learning_rate
		self.step_size = step_size
		self.scale_fn = scale_fn
		self.scale_mode = scale_mode
		self.name = name
	def __call__(self, step):
		with tf.name_scope(self.name or 'CyclicalLearningRate'):
			initial_learning_rate = tf.convert_to_tensor(
				self.initial_learning_rate, name = 'initial_learning_rate'
			)
			dtype = initial_learning_rate.dtype
			maximal_learning_rate = tf.cast(self.maximal_learning_rate, dtype)
			step_size = tf.cast(self.step_size, dtype)
			step_as_dtype = tf.cast(step, dtype)
			cycle = tf.floor(1 + step_as_dtype / (2 * step_size))
			x = tf.abs(step_as_dtype / step_size - 2 * cycle + 1)
			mode_step = cycle if self.scale_mode == 'cycle' else step
			return initial_learning_rate + (maximal_learning_rate - initial_learning_rate) * tf.maximum(tf.cast(0, dtype), (1 - x)) * self.scale_fn(mode_step)
	def get_config(self):
		return {
			'initial_learning_rate': self.initial_learning_rate,
			'maximal_learning_rate': self.maximal_learning_rate,
			'scale_fn': self.scale_fn,
			'step_size': self.step_size,
			'scale_mode': self.scale_mode
		}

class Distiller(tf.keras.Model):
	def __init__(self, student, teacher):
		super().__init__()
		self.student = student
		self.teacher = teacher
		self.loss_tracker = tf.keras.metrics.Mean(name = 'loss')
	@property
	def metrics(self):
		metrics = super().metrics
		metrics.append(self.loss_tracker)
		return metrics
	def compile(self, optimizer, metrics, distillationLossFunction, temperature = 10):
		super().compile(optimizer = optimizer, metrics = metrics)
		self.distillationLossFunction = distillationLossFunction
		self.temperature = temperature
	def _teacherImages(self, x):
		return tf.transpose(x, (0, 3, 1, 2))/255.0 ### [b, h, w, c] => [b, c, h, w]; scale [0.0, 1.0]
	def _studentImages(self, x):
		return x
		# return tf.image.resize(
		# 	antialias = False,
		# 	images = x,
		# 	method = 'bilinear',
		# 	preserve_aspect_ratio = False,
		# 	size = (settings['studentSize'], settings['studentSize']),
		# )
	def train_step(self, data):
		x, y, sample_weight = tf.keras.utils.unpack_x_y_sample_weight(data)
		teacherOutput = self.teacher(self._teacherImages(x))['output']
		with tf.GradientTape() as tape:
			studentOutput = self.student(self._studentImages(x), training = True)
			distillationLoss = self.distillationLossFunction(
				tf.nn.softmax(teacherOutput/self.temperature, axis = 1),
				tf.nn.softmax(studentOutput/self.temperature, axis = 1),
			)
		trainableWeights = self.student.trainable_variables
		gradients = tape.gradient(distillationLoss, trainableWeights)
		self.optimizer.apply_gradients(zip(gradients, trainableWeights))
		self.loss_tracker.update_state(distillationLoss)
		return {'loss': self.loss_tracker.result()}
	def test_step(self, data):
		x, y, sample_weight = tf.keras.utils.unpack_x_y_sample_weight(data)
		teacherOutput = self.teacher(self._teacherImages(x))['output']
		studentOutput = self.student(self._studentImages(x), training = False)
		distillationLoss = self.distillationLossFunction(
			tf.nn.softmax(teacherOutput/self.temperature, axis = 1),
			tf.nn.softmax(studentOutput/self.temperature, axis = 1),
		)
		self.loss_tracker.update_state(distillationLoss)
		self.compiled_metrics.update_state(y, studentOutput)
		return {m.name: m.result() for m in self.metrics}
	
def scale(x): 
	return 1.0/(2.0**(x-1))



### READ AND COMPILE MODEL
def modelInit(config):
	metrics = [
		tf.keras.metrics.CategoricalAccuracy(
			name = 'accuracy'
		),
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
	]
	schedulerLR = CyclicalLearningRate(
		initial_learning_rate = config['learningRate']/settings['clrInitial'],
		maximal_learning_rate = config['learningRate'],
		name = 'CyclicalLearningRate',
		scale_fn = scale,
		scale_mode = 'cycle',
		step_size = config['clrStep']*(2**config['batch'])
	)
	modelStudent = tf.keras.models.load_model(settings['modelStudent'], compile = False)
	modelTeacher = tf.saved_model.load(settings['modelTeacher'])
	modelTeacherInferenceEngine = modelTeacher.signatures['serving_default']
	distiller = Distiller(student = modelStudent, teacher = modelTeacherInferenceEngine)
	distiller.compile(
		distillationLossFunction = tf.keras.losses.KLDivergence(
			name = 'loss',
			reduction = 'sum_over_batch_size'
		),
		metrics = metrics,
		optimizer = tf.keras.optimizers.AdamW(
			amsgrad = False,
			beta_1 = settings['beta1'],
			beta_2 = settings['beta2'],
			clipnorm = None,
			clipvalue = None,
			ema_momentum = settings['ema_momentum'],
			ema_overwrite_frequency = None,
			epsilon = EPSILON,
			global_clipnorm = None,
			learning_rate = schedulerLR,
			name = 'AdamW',
			use_ema = False,
			weight_decay = config['weightDecay']
		),
		temperature = config['distillTemperature']	
	)
	return distiller



### GET CONFIG
bestConfig = {}
bestF1 = 0.0
maxIndex = max((ITERATION, SETTINGS, F1))+1
with open(os.path.join(settings['optimalSettings'], 'optimization-log.tsv'), mode = 'rt', encoding = 'utf8', errors = 'replace') as file:
	for k, line in enumerate(file):
		if k > 0:
			columns = line.strip().split('\t')
			if len(columns) >= maxIndex:
				f1 = float(columns[F1])
				if bestF1 < f1:
					bestF1 = f1
					bestConfig = json.loads(columns[SETTINGS])
settings['bestConfig'] = bestConfig
eprintWrap(f"Best F1 = {bestF1}, config = {json.dumps(bestConfig)}")



### TRAIN
random.seed(settings['randomSeed'])
tf.random.set_seed(random.randint(settings['randomMin'], settings['randomMax']))

trainData, validationData = dataInit(bestConfig)
model = modelInit(bestConfig)

history = model.fit(
	batch_size = 2**bestConfig['batch'],
	callbacks = [tf.keras.callbacks.EarlyStopping(
		baseline = None,
		min_delta = 0,
		mode = 'max',
		# monitor = 'val_auc',
		monitor = 'val_f1',
		patience = settings['patience'],
		restore_best_weights = True,
		verbose = 0
	)],
	epochs = settings['epochs'],
	validation_data = validationData,
	x = trainData
)

encoded = json.dumps(settings, ensure_ascii = False, indent = 3, sort_keys = True).encode()
hexMD5 = hashlib.md5(encoded).hexdigest()
directory = os.path.join(settings['outputDirectory'], f"{hexMD5}-best")
if not os.path.exists(directory):
	os.makedirs(directory)
model.student.save(os.path.join(directory, 'best-model.keras'))
np.save(os.path.join(directory, 'training-history.npy'), history.history, allow_pickle = True) ### history = np.load('file', allow_pickle = True).item()
with open(os.path.join(directory, 'training-settings.json'), 'w') as file:
	print(json.dumps(settings, ensure_ascii = False, indent = 3, sort_keys = True).encode(), file = file)



### DONE
sys.exit(0)
