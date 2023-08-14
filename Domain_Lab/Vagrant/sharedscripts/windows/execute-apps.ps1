$folderPath = "C:\vagrant\file\"  # Replace with the actual folder path

# Get all the executables from the specified folder
$executables = Get-ChildItem -Path $folderPath -Filter "*.exe" -File

# Loop through each executable and run it as administrator
foreach ($executable in $executables) {
    # Create a new process start info object
    $startInfo = New-Object System.Diagnostics.ProcessStartInfo
    $startInfo.FileName = $executable.FullName
    $startInfo.Verb = "runas"  # Run as administrator

    # Start the process
    [System.Diagnostics.Process]::Start($startInfo) | Out-Null
}
