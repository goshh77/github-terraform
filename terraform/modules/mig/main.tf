resource "google_compute_instance_template" "web" {
  name_prefix  = "${var.name}-tpl-"
  region       = var.region
  machine_type = var.machine_type
  tags         = ["web", "ssh-iap"]
  labels       = var.labels

  disk {
    source_image = var.image
    auto_delete  = true
    boot         = true
    disk_size_gb = 10
    disk_type    = "pd-balanced"
  }

  # Private only: no access_config => no external IP.
  network_interface {
    subnetwork = var.subnetwork_id
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  shielded_instance_config {
    enable_secure_boot          = true
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  metadata = {
    enable-oslogin = "TRUE"
  }

  metadata_startup_script = file("${path.module}/startup.sh")

  lifecycle {
    create_before_destroy = true
  }
}

# Used both for MIG auto-healing and by the load balancer backend service.
resource "google_compute_health_check" "web" {
  name                = "${var.name}-hc"
  check_interval_sec  = 10
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 3

  http_health_check {
    port         = 80
    request_path = "/healthz"
  }

  log_config {
    enable = true
  }
}

resource "google_compute_region_instance_group_manager" "web" {
  name               = "${var.name}-mig"
  region             = var.region
  base_instance_name = var.name

  version {
    name              = "primary"
    instance_template = google_compute_instance_template.web.self_link_unique
  }

  named_port {
    name = "http"
    port = 80
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.web.id
    initial_delay_sec = 300
  }

  # Rolling update whenever the template changes: surge new VMs, never drop capacity.
  update_policy {
    type                         = "PROACTIVE"
    instance_redistribution_type = "PROACTIVE"
    minimal_action               = "REPLACE"
    max_surge_fixed              = 3
    max_unavailable_fixed        = 0
  }

  # target_size is owned by the autoscaler.
}

resource "google_compute_region_autoscaler" "web" {
  name   = "${var.name}-autoscaler"
  region = var.region
  target = google_compute_region_instance_group_manager.web.id

  autoscaling_policy {
    min_replicas    = var.min_replicas
    max_replicas    = var.max_replicas
    cooldown_period = 90

    cpu_utilization {
      target = var.cpu_target
    }
  }
}
