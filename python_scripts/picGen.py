#!/usr/bin/env python3
#-*- coding: utf-8 -*-

from PIL import Image
import argparse
import numpy as np

def to8bitPixel(p):
    r, g, b = p
    r = int(r*8/256)
    g = int(g*8/256)
    b = int(b*4/256)
    return (r << 5) + (g << 2) + b

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', help = 'input image path', type = str, required = True)
    parser.add_argument('-o', help = 'output image path', type = str, default = './image.bmp')
    parser.add_argument('-vsize', help = 'output image vertical size', type = int, default = 450)
    parser.add_argument('-hsize', help = 'output image horizontal size', type = int, default = 600)
    args = parser.parse_args()
    img_path = args.i
    save_path = args.o
    img_vsize = args.vsize
    img_hsize = args.hsize
    img = Image.open(img_path)
    print(f"original img_size: {img.size}")
    img = img.resize((img_hsize, img_vsize), Image.ANTIALIAS)
    print(f"new img_size: {img.size}")
    data = np.apply_along_axis(to8bitPixel, arr=np.array(img), axis=2)
    img = Image.fromarray(np.uint8(data))
    img.save(save_path, 'bmp')
