# main.tf

provider "google" {
  project = var.project_id
  region  = "europe-west1"
}

# Enable required Google Cloud APIs
resource "google_project_service" "cloudfunctions" {
  project = var.project_id
  service = "cloudfunctions.googleapis.com"
}

resource "google_project_service" "cloud_build" {
  project = var.project_id
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "storage" {
  project = var.project_id
  service = "storage.googleapis.com"
}

resource "google_project_service" "iam" {
  project = var.project_id
  service = "iam.googleapis.com"
}

resource "google_project_service" "texttospeech" {
  project = var.project_id
  service = "texttospeech.googleapis.com"
}

resource "google_project_service" "eventarc" {
  project = var.project_id
  service = "eventarc.googleapis.com"
}

resource "google_project_service" "pubsub" {
  project = var.project_id
  service = "pubsub.googleapis.com"
}

resource "google_project_service" "cloud_run" {
  project = var.project_id
  service = "run.googleapis.com"
}

# Create a unique Cloud Storage bucket in 'europe-west1'
resource "google_storage_bucket" "cf_tts_bucket" {
  name          = "${var.bucket_name}-${random_id.bucket_id.hex}"
  location      = "europe-west1"
  force_destroy = true
}

resource "random_id" "bucket_id" {
  byte_length = 4
}

# Archive the function code (main.py and requirements.txt)
data "archive_file" "function_zip" {
  type        = "zip"
  source_dir  = "${path.module}/function"
  output_path = "${path.module}/function.zip"
}

# Upload the archived function code to the Cloud Storage bucket
resource "google_storage_bucket_object" "function_code" {
  name   = "function.zip"
  bucket = google_storage_bucket.cf_tts_bucket.name
  source = data.archive_file.function_zip.output_path
}

# Create a service account for the Cloud Function
resource "google_service_account" "text_to_speech_sa" {
  account_id   = "text-to-speech"
  display_name = "Text to Speech Function Service Account"
}

# Grant the service account editor access (temporary for testing)
resource "google_project_iam_member" "function_editor_access" {
  project = var.project_id
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.text_to_speech_sa.email}"
}

# Retrieve the project number
data "google_project" "project" {
  project_id = var.project_id
}

# Assign roles/eventarc.serviceAgent to the Eventarc Service Agent
resource "google_project_iam_member" "eventarc_service_agent_role" {
  project = var.project_id
  role    = "roles/eventarc.serviceAgent"
  member  = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

# Assign roles/pubsub.publisher to the Cloud Storage service agent
resource "google_project_iam_member" "cloud_storage_pubsub_publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"
  member  = "serviceAccount:service-${data.google_project.project.number}@gs-project-accounts.iam.gserviceaccount.com"
}

# Define the Cloud Function
resource "google_cloudfunctions2_function" "text_to_speech" {
  name     = "text-to-speech-function"
  location = "europe-west1"

  build_config {
    runtime     = "python312"
    entry_point = "process_file"
    source {
      storage_source {
        bucket = google_storage_bucket.cf_tts_bucket.name
        object = google_storage_bucket_object.function_code.name
      }
    }
  }

  service_config {
    service_account_email = google_service_account.text_to_speech_sa.email
  }

  event_trigger {
    event_type     = "google.cloud.storage.object.v1.finalized"
    trigger_region = "europe-west1"

    event_filters {
      attribute = "bucket"
      value     = google_storage_bucket.cf_tts_bucket.name
    }

    retry_policy = "RETRY_POLICY_RETRY"
  }

  depends_on = [
    google_project_service.cloudfunctions,
    google_project_service.cloud_build,
    google_project_service.texttospeech,
    google_project_iam_member.eventarc_service_agent_role,
    google_project_iam_member.cloud_storage_pubsub_publisher,
  ]
}

# IAM Binding for Cloud Run to allow Eventarc to invoke the function
resource "google_cloud_run_service_iam_member" "eventarc_invoker" {
  location = "europe-west1"
  project  = var.project_id
  service  = google_cloudfunctions2_function.text_to_speech.name
  role     = "roles/run.invoker"
  member   = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-eventarc.iam.gserviceaccount.com"
}

# Additional IAM roles for the service account
resource "google_project_iam_member" "eventarc_event_receiver" {
  project = var.project_id
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.text_to_speech_sa.email}"
}

resource "google_project_iam_member" "cloud_run_invoker" {
  project = var.project_id
  role    = "roles/run.invoker"
  member  = "serviceAccount:${google_service_account.text_to_speech_sa.email}"
}

# Output the name of the Cloud Storage bucket
output "bucket_name" {
  value = google_storage_bucket.cf_tts_bucket.name
}
