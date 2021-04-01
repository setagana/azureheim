# This suffix will be added to the names of your Azure resources, making them easy to find together
name_suffix = ""

# Choose an Azure datacenter location near you and your players
# For a list of all Azure locations, run the following command and then enter the Code for your location:
# az account list-locations --query "sort_by([*].{Name:regionalDisplayName, Code:name}, &Name)" -o table
location = ""

# The CPU and memory resources allocated to your server
# These default values have been tested with 3 concurrent players
# Increasing these values will improve performance with multiple players, but also your operating costs
server_cpu = 0.9
server_memory = 4

# If you're importing an existing world, you need to provide the name of your world. Leave this var as "" if you have no existing world data.
# This should match the .db file that you copy from your Valheim data directory
# E.G. if the file is MyWorld.db, you should set valheim_world_name to "MyWorld"
# If you choose to use the copy-world-data.ps1 script, this value will be set for you
valheim_world_name = ""

# Think of something memorable for you and your players
valheim_server_name = ""
