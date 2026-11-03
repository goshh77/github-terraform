resource "google_service_account" "this" {
  for_each = var.service_accounts

  project      = var.project_id
  account_id   = each.key
  display_name = each.value.display_name
}

locals {
  bindings = merge([
    for sa, cfg in var.service_accounts : {
      for role in cfg.roles : "${sa}|${role}" => { sa = sa, role = role }
    }
  ]...)
}

resource "google_project_iam_member" "this" {
  for_each = local.bindings

  project = var.project_id
  role    = each.value.role
  member  = "serviceAccount:${google_service_account.this[each.value.sa].email}"
}
