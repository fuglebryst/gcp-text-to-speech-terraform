# variables.tf

variable "project_id" {
  description = "The ID of the Google Cloud project."
  type        = string
  default     = ""  # Leave empty to use the environment variable or prompt at runtime.
}

variable "bucket_name" {
  description = "The base name of the Google Cloud Storage bucket. A random suffix will be added to ensure uniqueness."
  type        = string
  default     = "cf-tts"
}
