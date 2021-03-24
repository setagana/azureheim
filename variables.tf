variable "name_suffix" {
  type        = string
  description = "A suffix that will be added to your Azure resources to identify different servers"
}

variable "location" {
  type        = string
  description = "The region where your server will be hosted"
}

variable "valheim_world_name" {
  type        = string
  description = "The name of your Valheim world, as seen in the data files"
}

variable "valheim_server_name" {
  type        = string
  description = "The name of your Valheim server, which will be needed to find the server in the list of thousands of others"
}

variable "valheim_server_password" {
  type        = string
  description = "The password that your fellow players will use when connecting to the server"
  sensitive   = true
}

variable "server_cpu" {
  type        = number
  description = "Number of virtual CPUs to use for the server"
}

variable "server_memory" {
  type        = number
  description = "Number of gigabytes of memory to allocate to the server"
}
