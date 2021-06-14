if(!(Test-Path './dist')) {
  New-Item -Path '.' -Name 'dist' -ItemType 'directory'
}

# Run scripts
./Get-GfwList.ps1
