variable "key_pair"              { default = "", type = "string"}
variable "prefix"                { default = "workshop-"}

variable "subnet_cidr"           { default = "192.168.42.0/24"}
variable "vip_address"           { default = "192.168.42.42"}
variable "subnet_wildcard"       { default = "192.168.42.*"}
variable "floating_network_id"   { default = "f9c73cd5-9e7b-4bfd-89eb-c2f4f584c326"}
variable "floating_network_name" { default = "floating"}

variable "image_name"            { default = "Ubuntu 16.04 (LTS)"}
variable "flavor_name"           { default = "Small HD 2GB"}
variable "availability_zones"    { default = ["AMS-EQ1", "AMS-EQ3", "AMS-EU4"]}

## BASTION HOST
variable "bastion_name"          { default = "castle-black"}


variable "lb_count"              { default = 3}

variable "lb_flavor_id"          { default = 2002}

variable "web_count"             { default = 2}

variable "db_count"              { default = 2}
