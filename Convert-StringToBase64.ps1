#$str is some string
[Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($str))
