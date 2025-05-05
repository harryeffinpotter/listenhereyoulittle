echo "Downloading script..."
$DownloadURL = 'https://raw.githubusercontent.com/harryeffinpotter/listenhereyoulittle/master/install.bat'
$InitDownloadURL = 'https://raw.githubusercontent.com/harryeffinpotter/listenhereyoulittle/master/init.ps1'
$TempDir = "$env:TEMP"
$FilePath = "$TempDir\install.bat"
$InitPath = "$TempDir\init.ps1"

try
{
	Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
 	Invoke-WebRequest -Uri $InitDownloadURL -UseBasicParsing -OutFile $InitPath
}
catch
{
	Invoke-WebRequest -Uri $DownloadURL -UseBasicParsing -OutFile $FilePath
	Return
}
try
{
if (Test-Path $FilePath)
{
	Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
}
}
catch
{
Start-Process -Verb runAs $FilePath -Wait
	$item = Get-Item -LiteralPath $FilePath
	$item.Delete()
 }
