<#
.SYNOPSIS

SuperFind-Files is a utility to perform in-depth analysis of files in complex filesystems

.DESCRIPTION

You can use SuperFind-Files to find files by size, name, or contents. SuperFind-Files will find files:
- With duplicate filenames, contents, but under different absolute paths
- With duplicate filenames but different contents
- With different filenames but duplicate contents

The results can either be printed to the screen, or placed in a logfile

.PARAMETER Path

Optional. Specifies a path where the search will start. Default is current directory.

.PARAMETER Include

Optional. Use one or more initial filters on the files in the specified path before processing further (for list and/or duplicate-checking). Multiple filter statements need to be separated by commas. If wildcards are not included in each filter statement the search will only return exact filename matches. 

.PARAMETER Recurse

Optional. Specifies whether the script should recurse through the directory structure. Not set by default.

.PARAMETER List

Optional. Specifies whether filenames will be listed. If a log file basename is specified, files will be listed in a file named with the basename and "_files.log" appended.
If a log file basename is not specified, the list of files will be printed to the console.

.PARAMETER Duplicates

Optional. When used, the script with find duplicate filenames and/or files with duplicate contents. 

.PARAMETER AtLeast

Optional. When used, the script will only search through files that are over a specified number of bytes. The size can be given as a number concatenated to one of the below letters.

	K - Specifies kilobytes
	M - Specifies megabytes
	G - Specifies gigabytes

Note that the maximum value that should be specified by AtLeast is 4 gigabytes.

.PARAMETER Log <string>

Optional. Specify a log file basename, including full path. Path is not set by default. Note that since this is a basename, multiple logs may be generated from the basename, 
and each of the logs will have the .log extension. These files will be simple UTF-8 encoded text files.

    - If -Duplicates is set, files with duplicated contents will be in a log named <LOG STRING> + "_dup_c.log"; files with duplicate names will be in a log named <LOG STRING> + "dup_n.log"
    - If -List is set, all files will be listed in a log named <LOG STRING> + "_files.log"

.PARAMETER Verbose

Optional. Causes more detailed messages to be output to the screen. Useful if there are problems.

.EXAMPLE Search the current working directory, non-recursively, for duplicate files larger than 5 megabytes. Print output to the screen.

.\SuperFind-Files.ps1 -Duplicates -AtLeast 5M

.EXAMPLE Search "C:\Program Files" recursively, for duplicate .dll files. Print the output to c:\temp\c_programFiles_dup_n.log (duplicate filenames) and c:\temp\c_programfiles_dup_c.log (duplicate file contents)

.\SuperFind-Files.ps1 -Path "C:\Program Files" -Recurse -Duplicates -Include *.dll -Log c:\temp\c_programFiles 

.EXAMPLE Search "C:\Users\User" recursively, for .docx files greater than 700 kilobytes. Print the verbose output to the screen

.\SuperFind-Files.ps1 -Path "C:\Users\User" -Recurse -List -Include *.docx -AtLeast 700K -Verbose
#>

param(
[string]$path, 
[switch]$recurse=$false, 
[switch]$list=$false,
[switch]$duplicates=$false,
[string[]]$include='*',
[string]$atleast="0",
[string]$log="",
[switch]$verbose=$false
)

function WriteLog
{
    param(
    [string]$log_suffix="none",
    [string]$logstring,
    [string]$foregroundcolor="white"
    )
    #path suffix will be:
    #        _files.log for listing files
    #        _dup_c.log for duplicate Contents (either with or without duplicate filenames)
    #        _dup_n.log for duplicate fileNames (either with or without duplicate contents)
    
    if($log -eq "" -or $log_suffix -eq "none")
    {
        #if the path string is empty, assume we're writing to the screen
        write-host $logstring -ForegroundColor $foregroundcolor
    }
    else
    {
		if($log_suffix -ne "all")
		{
			#we shouldn't need to do any validation of the path since that happens in the main script body
			Add-Content -Value $logstring -Path ($log + $log_suffix)
		}
		else
		{
			if($list)
			{
				Add-Content -Value $logstring -path ($log + "_files.log")
			}
			if($duplicates)
			{
				Add-Content -Value $logstring -path ($log + "_dup_c.log"),($log + "_dup_n.log")
			}
		}
    }

}

$script_version="1.0"
$log_temp=$log

#we're temporarily setting log to an empty string so that writelog doesn't try to write to a non-existent log file while we're testing the path of the log file basename
$log=""

#this is a simple arraylist to keep track of any files that we can't process due to errors, such as insufficient R/W permissions
$fileNotProcessed=New-object System.Collections.ArrayList

#we need to test the directory of the log file basename given
if($log_temp -ne '')
{
    if($verbose)
    {
        WriteLog -logstring "[!] A log file basename was specified. Testing that the path exists..." -foregroundcolor yellow
    }
    if(!(test-path $log_temp.Substring(0,$log_temp.LastIndexOf('\'))))
    {
        WriteLog -logstring "[!!] Log file basename path invalid. The script will not be write to a log file." -ForegroundColor Red
        #clear the log file basename so that subsequently in the script we will not attempt to write to a bad path
        if($verbose)
        {
            WriteLog -logstring "[i] Clearing log file basename variable"
        }

        #log_temp gets set to an empty string so that $log will also be set to an empty string later
        $log_temp=""
    }
    else
    {
        if($verbose)
        {
            WriteLog -logstring "[*] Log file basename verified..." -foregroundcolor green
        }
    }
}
elseif($log_temp -eq '' -and $recurse)
{
    WriteLog -logstring "[!] Warning! A log file basename was not specified (-Log) but recursion was turned on (-Recurse). This script could potentially generate a LOT of output while doing recursive searches! I recommend at least redirecting output to a file" -foregroundcolor yellow
}
$log=$log_temp
WriteLog -log_suffix "all" -logstring "SuperFind-Files v$script_version"
WriteLog -log_suffix "all" -logstring "Path:    $path" 
WriteLog -log_suffix "all" -logstring "Filter:  $includes"
WriteLog -log_suffix "all" -logstring "AtLeast: $atLeast"
WriteLog -log_suffix "all" -logstring "Log:     $log_temp"

#no path specified?
if($path -eq "")
{
    if($verbose)
    {
        WriteLog -logstring "[!] No path specified. Defaulting to the current working directory" -foregroundcolor yellow
        WriteLog -logstring ("Current working directory: " + (pwd).Path)
    }
    #we'll use the current path
    $path = (pwd).path
}

#obviously we should test the path that we're given from the script invocation
if(!(test-path $path))
{
    WriteLog -logstring "[!!] Path not found. Exiting..." -ForegroundColor Red
    pause
    exit
}
if($verbose)
{
    WriteLog -logstring "[i] Instantiating hashtable for files"
}

$fileTable = new-object system.collections.hashtable

#we'll initialize the uint32 edition of AtLeast to 0, just in case it's not specified as a parameter
[uint32]$atleast_uint32=0

#parse out $atleast parameter, if it exists
if($verbose)
{
    WriteLog -logstring "[i] Parsing the AtLeast parameter. Default is 0 if not specified at invocation."
}

if($atleast.trim(' ') -ne '0' -and ($atleast.toupper().endswith('K') -or $atleast.toupper().endswith('M') -or $atleast.toupper().endswith('G')))
{

    if([System.UInt32]::TryParse($atleast.substring(0,$atleast.length),[ref]$atleast_uint32))
    {
        $atleast_uint32=[convert]::touint32($atleast.substring(0,$atleast.length))
    }
    else
    {
        WriteLog -logstring "[!!] Cannot use AtLeast parameter. Exiting..." -foregroundcolor red
        pause
        exit
    }



	if($atleast.toupper().endswith('K') -and $atleast_uint32 -le 4000000)
	{
		$atleast_uint32 *= 1000
	}
	elseif($atleast.toupper().endswith('M') -and $atleast_uint32 -le 4000)
	{
		$atleast_uint32 *= 1000000
	}
	elseif($atleast.toupper().endswith('G') -and $atleast_uint32 -le 4)
	{
		$atleast_uint32 *= 1000000000
	}
	else
	{
        writeLog -logstring "[!!] Cannot use AtLeast parameter. Exiting..." -foregroundcolor red
        pause
        exit
	}
	
}
elseif($atleast -ne $null -and ([System.UInt32]::TryParse($atleast.substring(0,$atleast.length),[ref]$atleast_uint32)))
{
	$atleast_uint32=[convert]::touint32($atleast)
	# we'll need to provide for the case where AtLeast can't be converted to a uint32
	# even though it's non-null
}
else
{
    writeLog -logstring "[!!] Cannot use AtLeast parameter. Exiting..." -foregroundcolor red
    pause
    exit
}

# main test: need to make sure the Path specified exists before we can continue
if(Test-Path $path)
{
	#first instance of work
	#should give the user some feedback that the script has started
    
	WriteLog -log_suffix "none" -logstring "[*] Ready to compile the list of files starting in $path" -foregroundcolor green

    if($verbose)
    {
        WriteLog -logstring "[!] Note: To avoid issues with files in the path, please ensure no files in the path are open`n" -foregroundcolor yellow
    }

    pause

	if($recurse)
	{
		WriteLog -log_suffix "all" -logstring "Recurse: Yes"
        ls -recurse -path $path -File -Include $includes  | %{if($_.Length -gt $atleast_uint32){try{$h=(get-filehash -al sha1 $_.fullname -erroraction stop).hash; $fileTable.Add(($_.fullname + "|" + $_.length),$h)}catch{$FileNotProcessed.Add($_)>$null}}}
	}
	else # $recurse is boolean
	{
		WriteLog -log_suffix "all" -logstring "Recurse: No"
        ls -path $path -File -Include $includes  | %{if($_.Length -gt $atleast_uint32){try{$h=(get-filehash -al sha1 $_.fullname -erroraction stop).hash; $fileTable.Add(($_.fullname + "|" + $_.length),$h)}catch{$FileNotProcessed.Add($_)>$null}}} 
    }
    if($verbose)
    {
        WriteLog -logstring "[i] Done gathering files and filenames into memory. It is safe to use files in $path now"
    }
}
else #if the path is not available
{
    WriteLog -log_path "all" -logstring "Could not find $path" -foregroundcolor red
    WriteLog -log_path "all" -logstring "We must exit now..." -foregroundcolor red
    pause
	exit
}

# now we have a hashtable of filenames and file hashes
# we can immediately dump the list of filenames w/paths for the $list switch

if($verbose)
{
    WriteLog -log_suffix "all" -logstring ("Number of files: " + $fileTable.Count)
}
if($list)
{
    #file log header
    #I don't really need these lines anymore, since I've decided each log will get this information in the header
    #WriteLog -log_suffix "_files.log" -logstring "List of files under $path"
    #if($atleast_uint32 -gt 0)
    #{
    #    WriteLog -log_suffix "all" -logstring ("Minimum size: " + $atleast)
    #}
    #else
    #{
    #    WriteLog -log_suffix "all" -logstring "No minimum size specified"
    #}
    WriteLog -log_suffix "_files.log" -logstring "`nPath|Size (bytes)"
    
    foreach($file in $fileTable.keys)
    {
        WriteLog -log_suffix "_files.log" -logstring $file
    }
}

if($duplicates)
{
    #newDuplicate tracks whether this set of file contents has been found and recorded before
    #it has to be initialized to TRUE because it's only checked if we find a hash that matches one we just saw ( hash(n) = hash(n-1) on our list, where n is the individual hash values we collected); so 
    [boolean]$newDuplicate=$true
    $lastFilename=""
    $lastHash=""

    $fileTable.GetEnumerator() | Sort-Object {$_.value} | foreach {
        if($_.value -eq $lastHash)
        {
            if($newDuplicate)
            {
                #record the filename in log, etc
                WriteLog -log_suffix "_dup_c.log" -logstring ""
                WriteLog -log_suffix "_dup_c.log" -logstring "================================================================================="
                WriteLog -log_suffix "_dup_c.log" -logstring ("Duplicated contents: "+$lastFilename)
                #signal to any subsequent duplicates that it's already been recorded as a "new duplicate"
                $newDuplicate=$false
            }
            WriteLog -log_suffix "_dup_c.log" -logstring $_.key.substring(0,$_.key.lastindexof('|'))
         }
         else #if the hash doesn't match the previous, reset the NewDuplicate
         {
            $newDuplicate=$true
            
         }

         $lastHash=$_.value
         $lastFilename=$_.key.substring(0,$_.key.lastindexof('|'))
    }

    $lastFilename=""
    $lastfullfilename=""
    $newDuplicate=$true

    $fileTable.GetEnumerator() | Sort-Object {$_.Key.substring($_.key.lastindexof('\')).trim('\')} | foreach {
        
        #the filenames all have the file size appended with the pipe character ( | ) as a delimiter
        #that means the actual filename has to be extracted from the hashtable key by including only the string before the pipe
        #for simplicity's sake, I'm using a new variable
        $temp_filename=$_.key.substring(0,$_.key.lastindexof('|'))  
        if($temp_filename.Substring($_.key.LastIndexOf('\')).trim('\') -eq $lastFilename)
        {
            if($newDuplicate)
            {
                WriteLog -log_suffix "_dup_n.log" -logstring ""
                WriteLog -log_suffix "_dup_n.log" -logstring "================================================================================="
                WriteLog -log_suffix "_dup_n.log" -logstring ("Duplicated filename: " + $lastfilename)
                WriteLog -log_suffix "_dup_n.log" -logstring $lastfullfilename
                $newDuplicate=$false
            }
            WriteLog -log_suffix "_dup_n.log" -logstring $temp_filename
        }
        else
        {
            $newDuplicate=$true

        }

        $lastFilename=$temp_filename.substring($_.key.lastindexof('\')).trim('\')
        $lastfullfilename=$temp_filename
    }

}
if($log -ne '')
{
    $final_write = "all"
}
else
{
    $final_write = "none"
}

if($filenotprocessed.Count -gt 0)
{
    if($verbose)
    {
        WriteLog -log_suffix $final_write -logstring ("`n[!] Files we were unable to process:`n"+ $filenotprocessed) -foregroundcolor yellow
    }
    else
    {
        WriteLog -logstring ("[!!] Please note: there were " + $filenotprocessed.Count + " file(s) we couldn't process! Running with the verbose flag prints the list to the logs...") -foregroundcolor red
        {
            if((Read-Host -Prompt "Would you like to dump the list to a file and to the screen? [y|n]").tolower() -eq 'y')
            {
                Add-Content -Path "FilesNotProcessed.txt" -value $fileNotProcessed
                WriteLog -log_suffix "none" -logstring "[!] Files not processed:`n$fileNotProcessed`n" -foregroundcolor yellow
				WriteLog -log_suffix "none" -logstring "[i] The above files have also been output to FilesNotProcessed.txt in the current directory (if you have write permissions here)" -foregroundcolor green
            }
        }
    }
}


#sort values (hashes) and display duplicate file contents
#$fileTable.GetEnumerator() | Sort-Object {$_.value} | foreach {if($_.value.tostring() -eq $x){write-host "Duplicate"};$x=$_.value.tostring()}

#$fileTable.GetEnumerator() | Sort-Object {$_.value} | foreach {$_.key.fullname}

#get-date -UFormat '%Y%m%d%H%M%S'
