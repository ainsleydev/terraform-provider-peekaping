terraform {
  required_providers {
    peekaping = {
      source = "tafaust/peekaping"
    }
  }
}

provider "peekaping" {
  # Configure with your API key
  # api_key = "your-api-key"
}

# Create a tag - this will be KNOWN
resource "peekaping_tag" "test_project" {
  name        = "Test Project"
  color       = "#3B82F6"
  description = "Test tag for debugging"
}

# Reference existing tags via data sources - these will be UNKNOWN during plan
data "peekaping_tag" "production" {
  name = "Production"
}

data "peekaping_tag" "webkit" {
  name = "WebKit"
}

# Create a monitor using mixed known/unknown tag IDs
resource "peekaping_monitor" "test" {
  name = "Test Monitor"
  type = "http"
  config = jsonencode({
    url                  = "https://example.com"
    method               = "GET"
    encoding             = "json"
    accepted_statuscodes = ["2XX"]
    authMethod           = "none"
  })

  interval        = 60
  timeout         = 30
  max_retries     = 3
  retry_interval  = 60
  resend_interval = 10
  active          = true

  # This should trigger the bug:
  # - First element: KNOWN (resource reference)
  # - Second element: UNKNOWN (data source, depends on create)
  # - Third element: UNKNOWN (data source, depends on create)
  tag_ids = [
    peekaping_tag.test_project.id,
    data.peekaping_tag.production.id,
    data.peekaping_tag.webkit.id,
  ]
}
