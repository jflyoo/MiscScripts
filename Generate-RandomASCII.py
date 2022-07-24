def main():
  from random import randint
  import argparse
  
  script_version="%(prog)s 1.0"

  parser = argparse.ArgumentParser(description="Quickly generate random strings of alphabetic characters of varying lengths")
  
  parser.add_argument('--minimumLength','-n',type=int,required=False,help='The minimum length of the random string',default=5)
  parser.add_argument('--maximumLength','-x',type=int,required=False,help='The maxmimum length of the random string',default=20)
  parser.add_argument("--version",action='version',version=script_version)
  args=parser.parse_args()
  
  if args.minimumLength <= args.maximumLength and args.minimumLength > 0 and args.maximumLength > 0:
    l=randint(args.minimumLength,args.maximumLength)
  else:
    print("Error!\n0 < Minimum < maximum\nAlso, you made me do math, so screw you!")
    exit()

  str_final = ''
  for x in range(1,l):
    can=chr(randint(65,90))
    if(randint(0,1) == 1):
      can=can.lower()
    str_final+=can
  
  print(str_final)

if __name__ == '__main__':
  main()