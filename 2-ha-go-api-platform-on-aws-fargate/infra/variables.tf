
//change this per project
locals {
    common_tags = {
        proj = "url-shortener"
        mng = "terraform"
    }
    prefix = "url-shortener"
    region = "ap-southeast-2"
}


variable "location" {
    default ="ap-southeast-2"
}