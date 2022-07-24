#VB Script Code to Change Word Doc PW
p = "test"
new_p = "test2"
file_path "c:\temp\test.docx"

Set doc = Documents _
	.Open(FileName:=file_path, PasswordDocument:=p)
	
doc.Password = new_p
doc.Close