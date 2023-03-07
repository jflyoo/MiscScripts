#!/usr/bin/env python3
# This script was developed to generate filenames that will blend into a target Windows environment
from random import randint
import argparse

script_version="%(prog)s 1.0"
parser = argparse.ArgumentParser(description="Quickly generate temporary file names for blending into the target environment")
parser.add_argument("--num","-n",type=int,required=False,help="The number of filenames to generate",default=3)

args=parser.parse_args()
def main():
  for i in range(0,args.num):
    out=''
    for i in range(0,32):
      if i in (8,13,18,23):
        out += '-'
      else:
        new = randint(0,15)
        if(new in range(0,10)):
          out += chr(0x30 + new)
        else:
          out += chr(0x61 + new - 0xa)
    print(f'{out}.tmp')    

if __name__ == '__main__':
  main()
