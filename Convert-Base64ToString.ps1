#$enc is the base64-encoded string
[System.Text.Encoding]::Unicode.GetString([Convert]::FromBase64String($enc))