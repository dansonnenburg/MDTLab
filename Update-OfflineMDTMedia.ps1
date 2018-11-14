param(
    $DriveLetter = 'C:'
)

Add-PSSnapIn Microsoft.BDD.PSSnapIn -ErrorAction SilentlyContinue
#Update Lab Kit media
New-PSDrive -Name "MEDIA001" -PSProvider "MDTProvider" -Root (Join-Path $DriveLetter "MDTLab\ISO\Content\Deploy") -Description "MDT Production Media" -Force -Verbose
Update-MDTMedia -path "DS001:\Media\MEDIA001" -Verbose -whatif