#!/usr/bin/env python3

### SAFE IMPORTS
import cv2
import getopt
import os
import re
import sys
import textwrap



### CONSTANTS
JPG = re.compile('\.jpg$')
#
# add try/except for docker
#
WRAP = 80 #int(os.get_terminal_size()[0])



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
settings['border'] = False
settings['inDirectory'] = ''
settings['inFile'] = ''
settings['outDirectory'] = ''
settings['outFile'] = ''
settings['preserve'] = False
settings['quality'] = 98
settings['size'] = 1024



### READ OPTIONS
inDirectoryError = 'Input image directory (directory or file required): -d directory | --inputDirectory=directory'
outDirectoryError = 'Output directory (required if input is a directory): -e directory | --outputDirectory=directory'
inFileError = 'Input image file (directory or file required): -f file | --inputFile=file'
outFileError = 'Output file (directory or file required): -g file | --outputFile=file'
try:
	arguments, values = getopt.getopt(sys.argv[1:], 'bd:e:f:g:hpq:s:', ['border', 'inputDirectory=', 'outputDirectory', 'inputFile=', 'outputFile', 'help', 'preserve', 'quality=', 'size='])
except getopt.error as err:
	eprintWrap(str(err))
	sys.exit(2)
for argument, value in arguments:
	if argument in ('-b', '--border'):
		settings['border'] = True
	elif argument in ('-d', '--inputDirectory'):
		if os.path.isdir(value):
			settings['inDirectory'] = value
		else:
			eprintWrap(f"Input directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-e', '--outputDirectory'):
		if os.path.isdir(value):
			settings['outDirectory'] = value
		else:
			eprintWrap(f"Output directory '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-f', '--inputFile'):
		if os.path.isfile(value):
			settings['inFile'] = value
		else:
			eprintWrap(f"Input file '{value}' does not exist!")
			sys.exit(2)
	elif argument in ('-g', '--outputFile'):
		settings['outFile'] = value
	elif argument in ('-h', '--help'):
		eprint('')
		eprintWrap('A Python3 script to resize images with openCV2.')
		eprintWrap(f"Add black padding around image (optional; default = {settings['border']}): -b | --border")
		eprintWrap(inDirectoryError)
		eprintWrap(outDirectoryError)
		eprintWrap(inFileError)
		eprintWrap(outFileError)
		eprintWrap(f"JPEG quality (optional; default = {settings['quality']}): -q int | --quality=int")
		eprintWrap(f"Preserve aspect ratio of output (optional; default = {settings['preserve']}): -p | --preserve")
		eprintWrap(f"Output image size in pixels of longest side (optional; default = {settings['size']}): -s int | --size=int")
		eprint('')
		sys.exit(0)
	elif argument in ('-p', '--preserve'):
		settings['preserve'] = True
	elif argument in ('-q', '--quality') and int(value) > 0 and int(value) <= 100:
		settings['quality'] = int(value)
	elif argument in ('-s', '--size') and int(value) > 0:
		settings['size'] = int(value)



### START/END
if not settings['inDirectory'] and not settings['inFile']:
	eprintWrap(inDirectoryError)
	eprintWrap(inFileError)
	sys.exit(2)
elif settings['inDirectory'] and not settings['outDirectory']:
	eprintWrap(outDirectoryError)
	sys.exit(2)
elif not settings['outDirectory'] and not settings['outFile']:
	eprintWrap(outDirectoryError)
	eprintWrap(outFileError)
	sys.exit(2)
else:
	eprintWrap('started...')
	for key, value in settings.items():
		eprintWrap(f"{key} = {value}")
	eprintWrap('')



### CONVERT
def convert(infile, outfile):
	try:
		image = cv2.imread(infile, cv2.IMREAD_COLOR)
		if settings['preserve']:
			x = image.shape[0]
			y = image.shape[1]
			if x > y:
				# ratio = settings['size']/x
				# resize = (int(y*ratio), settings['size'])
				ratio = settings['size']/y
				resize = (settings['size'], int(x*ratio))
			else:
				# ratio = settings['size']/y
				# resize = (settings['size'], int(x*ratio))
				ratio = settings['size']/x
				resize = (int(y*ratio), settings['size'])
		else: ### square to use all model weights
			resize = (settings['size'], settings['size'])
		image = cv2.resize(image, resize)
		if settings['border']:
			dx = settings['size']-resize[0]
			left = dx//2
			right = dx-left
			dy = settings['size']-resize[1]
			top = dy//2
			bottom = dy-top
			image = cv2.copyMakeBorder(image, top, bottom, left, right, cv2.BORDER_CONSTANT, value = [0, 0, 0])
		cv2.imwrite(outfile, image, (cv2.IMWRITE_JPEG_QUALITY, settings['quality']))
		eprintWrap(f"Saving '{outfile}'...")
	except:
		eprintWrap(f"File '{infile}' could not be processed. Skipping!")



### READ AND CONVERT
if settings['inDirectory']:
	for path, subdirs, files in os.walk(settings['inDirectory']):
		for file in files:
			if file.endswith('.jpg'):
				convert(os.path.join(path, file), os.path.join(settings['outDirectory'], file))
elif settings['outDirectory']:
	convert(settings['inFile'], os.path.join(settings['outDirectory'], os.path.basename(settings['inFile'])))
else:
	convert(settings['inFile'], settings['outFile'])



### DONE
sys.exit(0)
