# Simple Makefile for utility to turn BMP into
# simple RLE image format

../rle_images.h: Makefile BMPToRLE555.c
				gcc -Os -Wall -pedantic -o BMPToRLE555 BMPToRLE555.c
				./BMPToRLE555 -c colorcube.bmp rosco_web.bmp OSHW_UK000006.bmp -m rosco_logo.bmp >../rle_images.h
