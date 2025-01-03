#!/usr/bin/env python3

### SAFE IMPORTS
import cv2
import getopt
import numpy as np
import os
import random
import re
import shutil
import sys
import textwrap



### CONSTANTS
ALPHA_MAX = 0.32
ALPHA_MIN = 0.08
BLUR_MAX = 48
BLUR_MIN = 16
BRIGHTNESS_MAX = 8.0
BRIGHTNESS_MIN = 2.0
CORRUPTION = ('bgr', 'blur', 'double mask', 'JPEG artifact', 'mask', 'translucent mask')
CORRUPTIONS = len(CORRUPTION)
JPEG_MAX = 16
JPEG_MIN = 2 
OPAQUE = ((0,0,0),(128,128,128),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(128,128,128),(0,0,0),(128,128,128),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(0,0,0),(128,128,128),(0,0,0),(128,128,128),(0,0,0),(189,214,240),(128,128,128),(195,211,224),(128,128,128),(128,128,128),(0,0,0),(128,128,128),(128,128,128),(128,128,128),(128,128,128),(39,52,68),(128,128,128),(0,0,0),(0,0,0),(128,128,128),(128,128,128),(128,128,128),(128,128,128),(0,135,0),(128,128,128),(0,0,0),(128,128,128),(0,0,0),(0,0,0))
OPAQUE_MAX = len(OPAQUE)-1
OPAQUE_MEAN = 0.14781508823529	
OPAQUE_STD = 0.19861167383095
QUALITY_MAX = 64
QUALITY_MIN = 8
SATURATION_MAX = 5.0
SATURATION_MIN = 2.0
TRANSLUCENT_MEAN = 0.40889139090909
TRANSLUCENT_STD = 0.034609530457182
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
settings['inDirectory'] = ''
settings['outDirectory'] = ''
settings['quality'] = 94
settings['randomSeed'] = 123456789



### OTHER SETTINGS
settings['randomMax'] = 2**32 ### 64 is unsafe (53 is max safe)
settings['randomMin'] = 0



### READ OPTIONS
inDirectoryError = 'Input image directory (required): -i directory | --input=directory'
outDirectoryError = 'Output directory (required): -o directory | --output=directory'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'i:ho:q:r:', ['input=', 'help', 'output=', 'quality=', 'random='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-i', '--input'):
		if os.path.isdir(value):
			settings['inDirectory'] = value
		else:
			eprintWrap(f"Input directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to simulate image corruptions with openCV2.')
		eprintWrap(inDirectoryError)
		eprintWrap(outDirectoryError)
		eprintWrap(f"JPEG quality (optional; default = {settings['quality']}): -q int | --quality=int")
		eprintWrap(f"Random seed (optional; default = {settings['randomSeed']}): -r int | --random=int")
		eprint('')
		sys.exit(0)
	elif argument in ('-o', '--output'):
		if os.path.isdir(value):
			settings['outDirectory'] = value
		else:
			eprintWrap(f"Output directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-q', '--quality') and int(value) > 0 and int(value) <= 100:
		settings['quality'] = int(value)
	elif argument in ('-r', '--random') and int(value) >= settings['randomMin'] and int(value) <= settings['randomMax']:
		settings['randomSeed'] = int(value)



### START/END
if not settings['inDirectory']:
	eprintWrap(inDirectoryError)
	sys.exit(2)
elif not settings['outDirectory']:
	eprintWrap(outDirectoryError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")
	eprintWrap('')



### INIT
random.seed(settings['randomSeed'])



### READ FILES 
outputImages = {} ### input => output
inDirectory = re.compile(f"^{settings['inDirectory']}")
for path, subdirs, files in os.walk(settings['inDirectory']):
	for file in files:
		if file.endswith('.jpg'):
			outPath = re.sub(inDirectory, settings['outDirectory'], path)
			outputImages[os.path.join(path, file)] = os.path.join(outPath, file) 
			if not os.path.exists(outPath):
				os.makedirs(outPath)



### SHUFFLE AND CORRUPT
inputImages = random.sample(list(outputImages.keys()), len(list(outputImages.keys())))
for k, inputImage in enumerate(inputImages):
	# print(inputImage, outputImages[inputImage], k, k%CORRUPTIONS)
	try:
		corruption = k%CORRUPTIONS
		image = cv2.imread(inputImage, cv2.IMREAD_COLOR)
		h, w, c = image.shape
		if corruption == 0: ### BGR
			hsvImg = cv2.cvtColor(image, cv2.COLOR_BGR2HSV)
			hsvImg[..., 1] = hsvImg[..., 1]*random.uniform(SATURATION_MIN, SATURATION_MAX)
			hsvImg[..., 2] = hsvImg[..., 2]*random.uniform(BRIGHTNESS_MIN, BRIGHTNESS_MAX)
			image = cv2.cvtColor(hsvImg, cv2.COLOR_HSV2RGB)
		elif corruption == 1: ### BLUR
			kernel = random.randint(BLUR_MIN, BLUR_MAX)
			image = cv2.blur(image, (kernel, kernel))
		elif corruption == 2 or corruption == 4: ### [DOUBLE] MASK
			for _ in range(0, 1 if corruption == 4 else 2):
				bgr = OPAQUE[random.randint(0, OPAQUE_MAX)]
				yMax = int(max(np.random.normal(loc = OPAQUE_MEAN, scale = OPAQUE_STD, size = None), 0.0)*h)
				cv2.rectangle(
					color = bgr,
					img = image,
					pt1 = (0, h), 
					pt2 = (w, yMax),
					thickness = -1
				)
		elif corruption == 3: ### JPEG ARTIFACT
			for _ in range(0, random.randint(JPEG_MIN, JPEG_MAX)):
				imageBytes = cv2.imencode('.jpg', image, (cv2.IMWRITE_JPEG_QUALITY, random.randint(QUALITY_MIN, QUALITY_MAX)))[1]
				image = cv2.imdecode(imageBytes, cv2.IMREAD_COLOR) 
		else: ### TRANSLUCENT MASK
			yMax = int(max(np.random.normal(loc = TRANSLUCENT_MEAN, scale = TRANSLUCENT_STD, size = None), 0.0)*h)
			target = image[yMax:, :]
			overlay = np.zeros(target.shape, dtype = np.uint8)
			alpha = random.uniform(ALPHA_MIN, ALPHA_MAX)
			image[yMax:, :] = cv2.addWeighted(overlay, alpha, target, (1.0-alpha), 1.0)
		cv2.imwrite(outputImages[inputImage], image, (cv2.IMWRITE_JPEG_QUALITY, settings['quality']))
		eprintWrap(f"Saving '{outputImages[inputImage]}' as {CORRUPTION[corruption]}...")
	except:
		eprintWrap(f"File '{inputImage}' could not be processed. Skipping!")



### DONE
sys.exit(0)
