#!/usr/bin/env python
import requests
import argparse
script_version="%(prog)s 1.0"

parser = argparse.ArgumentParser(description="Quickly test validity of a list of URLs")
  
parser.add_argument('--listFile','-l',type=str,required=True,help='A file containing the list of URLs')
parser.add_argument('--verbose', '-v',default=False,action='store_true',help='Make the script print each attempted URL and result')
parser.add_argument('--output','-o',required=False,default='_urls',help='Basename for output files')
parser.add_argument("--version",'-V',action='version',version=script_version)
args=parser.parse_args()

def writeout(suffix, entry):
  with open("{0}-{1}".format(args.output, suffix), 'a') as g:
    g.write(entry + '\n')

def printerror(err):
  print("We had an error: {0}\n---->{1}".format(line, err))

with open(args.listFile,'r') as f:
  for line in f:
    line = line.strip('\n')
    if not line.endswith('/') and not line.endswith('html') and not line.endswith('php') and not line.endswith('asp') and not line.endswith('aspx'):
      line = line + "/"
    try:
      headers = {'user-agent': 'Mozilla/5.0 (X11; Linux x86_64; rv:109.0) Gecko/20100101 Firefox/115.0'}
      r = requests.get(line, headers=headers, allow_redirects=True)
      if args.verbose == True:
        print('{0}\n---->returned {1}'.format(line, r.status_code))
        continue
      elif r.status_code != 200 and r.status_code != 301 and args.verbose == False:
        print('Error: {0}\n---->returned {1}'.format(line, r.status_code))
        writeout("bad",line)
    except requests.exceptions.ConnectionError:
      printerror("ConnectionError (network issues, such as DNS error, service rejected, etc)") 
      writeout("connectionError",line)
    except requests.URLRequired:
      printerror("URLRequired (invalid URL)")
      writeout("invalidURL",line)
    except requests.exceptions.MissingSchema:
      printerror("MissingSchema (invalid URL)")
      writeout("invalidURL",line)
    except Exception as e:
      printerror(str(e))
      writeout("otherError",line)
