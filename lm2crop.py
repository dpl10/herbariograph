#!/usr/bin/env python3

### SAFE IMPORTS
import cv2
import getopt
import json
import os
import re
import shutil
import sys
import textwrap
from geojson import Feature, FeatureCollection
from turfpy.measurement import envelope
from turfpy.transformation import intersect



### CONSTANTS
BUFFER = 10
COMPRESSION = 94
JSON = re.compile(r'^Detections_Plant_Components.json$')
JPG = re.compile(r'\.jpg$')
HEX = re.compile(r'^[0-9a-f]{16,16}$')
SIZE = 1024
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
settings['inImageDirectory'] = ''
settings['inJsonDirectory'] = ''
settings['outDirectory'] = ''



### READ OPTIONS
inImageDirectoryError = 'Input image directory (required): -i directory | --input=directory'
inJsonDirectoryError = 'Input JSON directory (required): -j directory | --json=directory'
outDirectoryError = 'Output image directory (required): -o directory | --output=directory'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'hi:j:o:', ['help', 'input=', 'json=', 'output='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to make specimen crops from LeafMachine2 output.')
		eprintWrap(inImageDirectoryError)
		eprintWrap(inJsonDirectoryError)
		eprintWrap(outDirectoryError)
		eprint('')
		sys.exit(0)
	elif argument in ('-i', '--input'):
		if os.path.isdir(value):
			settings['inImageDirectory'] = value
		else:
			eprintWrap(f"Input directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-j', '--json'):
		if os.path.isdir(value):
			settings['inJsonDirectory'] = value
		else:
			eprintWrap(f"Input directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-o', '--output'):
		if os.path.isdir(value):
			settings['outDirectory'] = value
		else:
			eprintWrap(f"Output directory '{value}' does not exist!")
			sys.exit(2)



### START/END
if not settings['inImageDirectory']:
	eprintWrap(inImageDirectoryError)
	sys.exit(2)
elif not settings['inJsonDirectory']:
	eprintWrap(inJsonDirectoryError)
	sys.exit(2)
elif not settings['outDirectory']:
	eprintWrap(outDirectoryError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")
	eprintWrap('')



### BBOX FUNCTIONS
def centerImage(image, xMin, xMax, yMin, yMax):
	horizontal = (xMax-xMin) > (yMax-yMin)
	grayImage = cv2.cvtColor(image[yMin:yMax, xMin:xMax], cv2.COLOR_BGR2GRAY)
	blurred = cv2.GaussianBlur(grayImage, (7, 7), 0)
	_, threshold = cv2.threshold(blurred, 0, 255, cv2.THRESH_BINARY_INV | cv2.THRESH_OTSU)
	moments = cv2.moments(threshold)
	xCenter = int(moments['m10']//moments['m00'])
	yCenter = int(moments['m01']//moments['m00'])
	return horizontal, xCenter, yCenter

def feature2xxyy(feature, number):
	x = xyExtract(feature, 0)
	y = xyExtract(feature, 1)
	if number == 'float':
		return (float(min(x)), float(max(x)), float(min(y)), float(max(y)))
	else:
		return (int(min(x)), int(max(x)), int(min(y)), int(max(y)))

def mergeBoxes(boxes):
	bboxes = {}
	for xxyy in boxes:
		bboxes[xxyy2key(xxyy)] = xxyy2feature(xxyy)
	merged = True
	while merged:
		merged = testMerge(bboxes)
	output = []
	for bbox in bboxes.values():
		output.append(feature2xxyy(bbox, 'int'))
	return output

def rectangle(height, horizontal, size, width, xCenter, yCenter, xMax, yMax):
	if width > height:
		ratio = size/height
		long = int(width*ratio)
	else:
		ratio = size/width
		long = int(height*ratio)
	if horizontal:
		halfSizeHorizontal = long//2
		halfSizeVertical = size//2
	else:
		halfSizeHorizontal = size//2
		halfSizeVertical = long//2
	left = xMax-xCenter-halfSizeHorizontal
	right = xMax-xCenter+halfSizeHorizontal
	top = yMax-yCenter+halfSizeVertical
	bottom = yMax-yCenter-halfSizeVertical
	return left, right, top, bottom

def testMerge(bboxes):
	bboxKeys = list(bboxes.keys())
	for k in range(0, len(bboxKeys)-1):
		for j in range(k+1, len(bboxKeys)):
			if intersect([bboxes[bboxKeys[k]], bboxes[bboxKeys[j]]]):
				newBox = envelope(FeatureCollection([bboxes[bboxKeys[k]], bboxes[bboxKeys[j]]]))
				newBoxKey = xxyy2key(feature2xxyy(newBox, 'float'))
				del bboxes[bboxKeys[k]]
				del bboxes[bboxKeys[j]]
				bboxes[newBoxKey] = newBox
				return True
	return False

def xxyy2feature(xxyy):
	(xMin, xMax, yMin, yMax) = xxyy
	return Feature(geometry = {
		'coordinates': [[
			[xMax+BUFFER, yMin-BUFFER], 
			[xMax+BUFFER, yMax+BUFFER],
			[xMin-BUFFER, yMax+BUFFER], 
			[xMin-BUFFER, yMin-BUFFER],
			[xMax+BUFFER, yMin-BUFFER]
		]], 
		'type': 'Polygon'
	})

def xxyy2key(xxyy):
	(xMin, xMax, yMin, yMax) = xxyy
	return f"{xMin}|{xMax}|{yMin}|{yMax}"

def xyExtract(feature, k):
	return [
		feature['geometry']['coordinates'][0][0][k], 
		feature['geometry']['coordinates'][0][1][k], 
		feature['geometry']['coordinates'][0][2][k], 
		feature['geometry']['coordinates'][0][3][k], 
		feature['geometry']['coordinates'][0][4][k]
	]

def yolo2xxyy(x, y, w, h, width, height):
	left = int((x-(w/2))*width)
	right = int((x+(w/2))*width)
	top = int((y-(h/2))*height)
	bottom = int((y+(h/2))*height)
	if left < 0:
		left = 0
	if right > width-1:
		right = width-1
	if top < 0:
		top = 0
	if bottom > height-1:
		bottom = height-1
	return left, right, top, bottom



### READ JSON FILES
detections = {} ### file => [[YOLOv5], ...]
for path, subdirs, files in os.walk(settings['inJsonDirectory']):
	for file in files:
		if re.search(JSON, file):
			with open(os.path.join(path, file)) as jsonFile:
				jsonData = json.load(jsonFile)
				for key in jsonData:
					if re.search(HEX, key):
						if 'Detections_Plant_Components' in jsonData[key]:
							if key not in detections:
								detections[key] = []
							for bbox in jsonData[key]['Detections_Plant_Components']:
								if len(bbox) == 5:
									detections[key].append(bbox)
							if len(detections[key]) == 0:
								del detections[key]
								eprintWrap(f"No specimen detection for {key} in {os.path.join(path, file)}...")

if len(detections) == 0:
	eprintWrap(f"No specimens detected...")
	sys.exit(1)



### CROP
for path, subdirs, files in os.walk(settings['inImageDirectory']):
	for file in files:
		if file.endswith('.jpg'):
			eprintWrap(f"Processing '{os.path.join(path, file)}'...")
			xxhash = re.sub(JPG, '', file)
			image = cv2.imread(os.path.join(path, file), cv2.IMREAD_COLOR)
			if image is None:
				eprintWrap(f"Failed to open '{os.path.join(path, file)}'! Aborting...")
				continue
			height, width, _ = image.shape
			if xxhash in detections:
				boxes = []
				for (_, x, y, w, h) in detections[xxhash]:
					left, right, top, bottom = yolo2xxyy(x, y, w, h, width, height)
					boxes.append((left, right, bottom, top))
				for (xMin, xMax, yMin, yMax) in mergeBoxes(boxes):
					if xMax > xMin and yMax > yMin and min(xMin, xMax, yMin, yMax) > 0:
						horizontal, xCenter, yCenter = centerImage(image, xMin, xMax, yMin, yMax)
						left, right, top, bottom = rectangle(height, horizontal, SIZE, width, xCenter, yCenter, xMax, yMax)
						if left >= 0 and right <= width and top <= height and bottom >= 0:
							parent = os.path.join(*(path.split(os.path.sep)[1:]))
							outDir = os.path.join(settings['outDirectory'], parent)
							if not os.path.exists(outDir):
								os.makedirs(outDir)
							outFile = os.path.join(outDir, file)
							cv2.imwrite(outFile, image[bottom:top, left:right, :],  [cv2.IMWRITE_JPEG_QUALITY, COMPRESSION])
							eprintWrap(f"Saved '{outFile}'...")



### END
sys.exit(0)
