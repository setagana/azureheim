# Using An Existing World

You can move an existing Valheim world to a server by copying three data files and setting a value in the `config.tfvars` file.

## Copying The Files

### Manual Copy

If you'd prefer to copy the files by hand, do the following:

1. Press Win+R to open the Run window
2. Enter `%userprofile%\AppData\LocalLow\IronGate\Valheim\worlds` and hit enter
3. Copy the `.db`, `.db.old` and `.fwl` files for your existing world
4. Paste them in the same folder as `main.tf`

### Helper Script

The steps described above have also been written into a Powershell script for your convenience. Open a command prompt in the folder containing `copy-world-data.ps1` and enter the following command:

```
PowerShell.exe -ExecutionPolicy Bypass -File copy-world-data.ps1
```

## Setting The Variable

If you manually copied the files, open the `config.tfvars` file and edit the `valheim_world_name` variable as per the comment. If you used the helper script, this variable will already be set for you.