provider "google" {
  project     = "genzouw-xx-273608"
  region      = "asia-northeast1-a"
}

resource "google_pubsub_topic" "terraform-topic" {
  name = "terraform-topic"
}

resource "google_pubsub_subscription" "terraform-subscription" {
  name  = "terraform-subscription"
  topic = google_pubsub_topic.terraform-topic.name

  message_retention_duration = "604800s"
  retain_acked_messages      = true

  ack_deadline_seconds = 10

  enable_message_ordering    = false
}
