# This script is a slight adaptation of the PowerShell script found at this location:
# https://stackoverflow.com/questions/1001776/how-can-i-split-a-text-file-using-powershell

# Example usage: 
# Import into a PowerShell session, then run the below:
# Split-File -FromPath <source path> 

# The output will be placed in the same directory as the source file
# By default each piece will be 10MB in size
Function Split-File 
{
param($FromPath,
$BaseName = "{0}_section" -f ($FromPath)
)

$ext = "txt"
$upperBound = 10MB


$FromFile = [io.file]::OpenRead($FromPath)
$buff = new-object byte[] $upperBound
$count = $idx = 0
try {
    do {
        "Reading $upperBound"
        $count = $fromFile.Read($buff, 0, $buff.Length)
        if ($count -gt 0) {
            $to = "{0}.{1}.{2}" -f ($BaseName, $idx, $ext)
            $toFile = [io.file]::OpenWrite($to)
            try {
                "Writing $count to $to"
                $tofile.Write($buff, 0, $count)
            } finally {
                $tofile.Close()
            }
        }
        $idx ++
    } while ($count -gt 0) # End of do while loop
} # End of try
finally {
    $fromFile.Close()
} # End of finally
} # End of function
