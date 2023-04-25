#!/usr/bin/env bash
#This script will search file2.txt and remove lines which also appear in file1.txt; the result will be in file3.txt 
if [[ $# < 2 ]]
then
       	echo -e "Usage: Dedup-Lists.sh file1 file2 file3\n\n       Only file1 and file2 need to exist"
	exit
fi
file1=$1
file2=$2
if [[ $# < 3 ]]
then
	file2=$2.old
	file3=$2
else
	file3=$3
fi

#because of the way that sed works, we want to make a copy of file2 and operate sed with -i option on that copy
cp $file2 $file3

for l in $(cat $file1); do sed -i "/^$l$/d" $file3 2>/dev/null; done
