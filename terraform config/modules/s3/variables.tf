variable "kms_key_id" {
  description = "arn for kms key"
}

variable "tags" {
  description = "vpc tags"
}

variable "log_archive_days" {
  description = "Number of days to wait before archiving to Glacier"
  type        = number
  default     = 30
}

variable "log_expire_days" {
  description = "Number of days to wait before deleting"
  type        = number
  default     = 365
}
