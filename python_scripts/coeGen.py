#!/usr/bin/env python3
#-*- coding: utf-8 -*-

from PIL import Image
import argparse
import numpy as np

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('-i', help = 'input image path', type = str, nargs = '+', required = True)
    parser.add_argument('-o', help = 'output coe file path', type = str, default = './output.coe')
    parser.add_argument('-radix', help = 'output coe file radix', type = int, default = 2)
    args = parser.parse_args()
    img_paths = args.i
    save_path = args.o
    radix = args.radix
    data = np.array([np.array(Image.open(img_path)).flatten().tolist() for img_path in img_paths]).flatten().tolist()
    assert int(len(data)/4) == len(data)/4
    data = np.vectorize(lambda x: format(x, '08b'))(data).reshape((int(len(data)/4), 4))
    data = np.apply_along_axis(lambda x: "".join(x), arr=data, axis=1).tolist()
    output_file = open(save_path, 'w')
    write_n = output_file.write(f'memory_initialization_radix = {radix};\n')
    write_n += output_file.write(f'memory_initialization_vector = \n')
    write_n += output_file.write(",\n".join(data)+';\n')
    output_file.close()
    print(f"write {write_n} bytes.")
