import argparse
import xml.etree.ElementTree as ET
#this piece of code assumes that each XML node has a namespace. the XML parser will expand the name of each tag to include the name of the namespace enclosed in {} (curly-braces)
#therefore, we'll record each tag along with all its parent nodes in a list
def c(t,l,p):
  pTh=p+'.'+t.tag
  if(pTh not in l):
    l.append(pTh)
  for d in t.findall('./'):
    c(d,l,pTh)

def main():   
  script_version="%(prog)s 1.0"
  
  parser = argparse.ArgumentParser(description="Take an XML file and print out a simple tree to show how each element relates to others.")
  parser.add_argument("--xml", type=str, help="Path to the XML file")
  parser.add_argument("--version",action='version',version=script_version)
  args=parser.parse_args()
  print(f"Printing XML: ",args.xml)
  #here we grab the XML and parse
  try:
    tree=ET.parse(args.xml)
    root=tree.getroot()
  except Exception as E:
    print(f"Error! We have to exit!\n",E)
    exit()
  
  alist=[]
  
  #build the list from the parsed XML
  c(root,alist,'')
  
  #we'll sort the list so that the list comes out with all parents above their children
  alist.sort()
  #unfortunately, there's no getLastIndexOf function in python, so...what to do?
  #each entry is prefixed with all its parents, with periods between the entries
  #of course, we want to be able to parse the XML regardless of whether namespaces are used
  #we have to test to see if there are curly braces in our first entry in the list we created
  
  
  splitter = '}'
  #if not, we'll test if there are any periods in our first entry
  
  #then, reverse the entry, find print everything in the entry up to the first (actually last) curly-brace, then reverse the entry again
  #of course, this only works if we a) have namespaces in the first place; if there are no namespaces, we would need to find the number of periods in the 
  #entry and use that to determine where in the tree each entry belongs
  if (alist[0].count(splitter) == 0):
    splitter = '.'
  
  #in the case there are neither periods or curly-braces, we're dealing with XML that I haven't foreseen so we need to exit
    if(alist[0].count(splitter) == 0):
      print("Error! We cannot display a pretty tree of this XML!")
      print("Here's a raw dump of what we found...\\n\\n")
      for entry in alist:
        print(entry)
      exit()      
  
  #if we can use one of the two splitting characters above, for each entry, first we count the instances of the splitting character to get an idea of where in the tree it belongs
  for entry in alist:
    indent = '   ' * entry.count(splitter)
  
  #then we print a string prefixed with the appropriate number of spaces 
    print('{0}{1}'.format(indent, entry[::-1].split(splitter)[0][::-1]))

if __name__ == '__main__':
  main()