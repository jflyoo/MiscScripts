# this is a collection of commands that I know work to accomplish the task of correcting XML tags
# the script aspect of if is still a work-in-progress
# uploading to github to establish version control ONLY! This is not ready for any sort of release as of 27 Mar 2022
# Get all the tags that are messed up in file.xml
grep -o -E '&lt;(/)?\w*?&gt;' file.xml | sort -u

#single sed command to replace multiple character matches in the example string
r=`echo '&lt;VulnDiscussion&gt;' | sed -e 's.&lt;.<.' -e 's.&gt;.>.'`

#this is the beginnings of the loop to do the replacements
for x in '&lt;VulnDiscussion&gt;'; do replacement=`echo $x | sed -e 's.&lt;.<.' -e 's.&gt;.>.'`; sed -i -e "s.$x.$r." file.xml ; done

#first attempt at script; we're operating on file.xml
f='file.xml'
echo Number of bad tags: $(grep -c -E '&lt;(/)?\w*?&gt;' $f)
for x in `grep -o -E '&lt;(/)?\w*?&gt;' $f | sort -u`; do replacement=`echo $x | sed -e 's.&lt;.<.' -e 's.&gt;.>.'`; echo "Replacing $x with $r"; sed -e "s.$x.$r."> $f.scriptfixed ; done
echo New count of potential bad tags: $(grep -c -E '&lt;(/)?\w*?&gt;' $f.scriptfixed)

#my attempt at a one-liner to change the non-tags back to HTML encoding
f='file.xml.scriptfixed'
cp $f $f.2
for x in '&lt;devicename&gt;' '&lt;file&gt;' '&lt;group&gt;' '&lt;INIT_FILE&gt;' '&lt;SAN&gt;' '&lt;user&gt;'  ; do r=`echo $x | sed -i -e "s.<.&lt;." -e "s.>.&gt;."` ; echo Changing $x to $r; sed -i -e "s.$x.$r." $f.2 ; done;

#of course, the above doesn't work because the ampersand is a reserved character in the sed program!
#in my further testing of this problem, I've discovered I need the below command to be passed to sed
sed -i -e "s.<devicename>.\&lt;devicename\&gt;." $f.2

# to setup the r variable, this is the command I need to run; this will get me a string suitable for the above "final" sed command
echo $x | sed -e "s.<.\&lt;." -e "s.>.\&gt;." -e 's.\&.\\&.g'

# had to change the above command slightly in the loop
for x in '<devicename>' '<file>' '<group>' '<INIT_FILE>' '<SAN>' '<user>'  ; do r=`echo $x | sed -e "s.<.\&lt;." -e "s.>.\&gt;." -e 's.\&.\\\&.g'` ; echo "Changing $x to $r"; sed -i -e "s.$x.$r." $f.2 ; done;
