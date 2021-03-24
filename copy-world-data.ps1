# Set a variable with the path to the Valheim world data of your user
$valheimWorldDataFolder = "$Env:USERPROFILE\AppData\LocalLow\IronGate\Valheim\worlds"
# Open a GUI to select a .db file from your Valheim world data folder
$filePaths = @(Get-ChildItem "$valheimWorldDataFolder\*.db" | Out-GridView -Title 'Select a Valheim world to import' -PassThru)
$dbFilePath = $filePaths[0]
# Get the name of your world based on the file you selected
$worldName = [System.IO.Path]::GetFileNameWithoutExtension($dbFilePath)
# Copy your world's .db file to the current directory
Copy-Item $dbFilePath
# Copy your world's .db.old file to the current directory
Copy-Item "$dbFilePath.old"
# Copy your world's .fwl file to the current directory
Copy-Item "$valheimWorldDataFolder\$worldName.fwl"
# Find the line of your terraform config file that specifies the world name
$line = Get-Content config.tfvars | Select-String 'valheim_world_name =' | Select-Object -ExpandProperty Line
# Load the config.tfvars file
$content = Get-Content "$PSScriptRoot\config.tfvars"
# Replace the valheim_world_name line with the name of your world
$content | ForEach-Object { $_ -replace $line, "valheim_world_name = ""$worldName""" } | Set-Content "$PSScriptRoot\config.tfvars"