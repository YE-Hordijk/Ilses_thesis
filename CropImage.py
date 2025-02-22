from PIL import Image, ImageChops

def trim(im):
	bg = Image.new(im.mode, im.size, im.getpixel((0,0)))
	diff = ImageChops.difference(im, bg)
	diff = ImageChops.add(diff, diff, 2.0, -100)
	bbox = diff.getbbox()
	if bbox:
		return im.crop(bbox)

def crop(path):
	im = Image.open(path)
	im = trim(im)
	im.save(path,  bbox_inches = 'tight')

