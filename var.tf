variable "resource_group_name" {
  description = "Name of the resource group to be imported."
  type        = string
}

##NOTE: Due to time constraints i didn't add description field for each variable. 

variable "rglocation" {
  
  type        = string
  default     = "East US"
}

variable "vnet_name" {
 
  type        = string
  
}

variable "vnet_cidr_prefix" {
  type        = string
  

# If no values specified, this defaults to Azure DNS 
variable "websubnet_cidr_prefix" {
  
  type        = string

}

variable "appsubnet_cidr_prefix" {
  
  type        = string

}

variable "DBsubnet_cidr_prefix" {
  
  type        = string

}

variable "jumpsubnet_cidr_prefix" {
  
  type        = string


variable "websubnet" {
  
  type        = string

}

variable "appsubnet" {
 
  type        = string

variable "DBsubnet" {
  
  type        = string

}

variable "jumpsubnet" {
 
  type        = string

}

variable "web_pub_ip" {

  type        = string

}

variable "jump_pub_ip" {

  type        = string

variable "web_nic_prefix" {

  type        = string

}

variable "app_nic_prefix" {

  type        = string

}

variable "db_nic_prefix" {

  type        = string

variable "jump_nic_prefix" {

  type        = string

}

variable "webserver_name" {

  type        = string

variable "web_vm_size" {
  
  type        = string
}

variable "app_vm_size" {
  
  type        = string
}

variable "appserver_name" {
 
  type        = string
}

variable "dbserver_name" {
  
  type        = string
}

variable "jumpserver_name" {
  
  type        = string
}

variable "db_vm_size" {
  
  type        = string
}

variable "jump_vm_size" {
 
  type        = string
}


variable "vm_username" {
 
  type        = string
}

variable "image_publisher" {
  
  type        = string
 
}
variable "image_offer" {
  
  type        = string
}
variable "image_sku" {
  
  type        = string
}
variable "image_version" {
  
  type        = string
}
variable "disk_caching" {
  
  type        = string
}
variable "storage_account_type" {
  
  type        = string
}
