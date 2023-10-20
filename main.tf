terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 5.0"
    }
  }
}

provider "github" {
  token = var.token
  owner = var.organisation
}

variable "token" {
  type      = string
  sensitive = true
  default   = "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" 
}

variable "organisation" {
  type    = string
  default = "Practical-DevOps-GitHub"
}

variable "repository_name" {
  description = "(Required) The name of the repository."
  type        = string
  default     = "github-terraform-task-Amor19999"
}

variable "collaborators" {
  type = map(string)
  default = {
    "softservedata" = "admin"
  }
}

variable "branches" {
  type    = set(string)
  default = ["main", "develop"]
}

variable "discord_webhook_events" {
  type    = list(string)
  default = ["pull_request", "pull_request_review", "pull_request_review_comment", "pull_request_review_thread", "push"]
}

variable "action_token" {
  type      = string
  sensitive = true
  default   = "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" 
}

resource "github_repository_collaborator" "collaborator" {
  for_each = var.collaborators

  username   = each.key
  permission = each.value
  repository = var.repository_name
}

resource "github_branch" "develop" {
  repository    = var.repository_name
  branch        = "develop"
  source_branch = "main"
}

resource "github_branch_default" "this" {
  branch     = "develop"
  repository = var.repository_name
  depends_on = [github_branch.develop]
}

resource "github_branch_protection" "main" {
  pattern       = "main"
  repository_id = var.repository_name
  required_pull_request_reviews {
    require_code_owner_reviews      = true
    required_approving_review_count = 0
  }
}

resource "github_branch_protection" "develop" {
  pattern       = "develop"
  repository_id = var.repository_name
  required_pull_request_reviews {
    required_approving_review_count = 2
  }
}

resource "tls_private_key" "deploy_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "github_repository_deploy_key" "deploy_key" {
  key        = tls_private_key.deploy_key.public_key_openssh
  repository = var.repository_name
  title      = "DEPLOY_KEY"
}

resource "github_repository_file" "pull_request_template" {
  for_each            = var.branches
  content             = <<EOT
  ## Describe your changes

  ## Issue ticket number and link

  ## Checklist before requesting a review
  - [ ] I have performed a self-review of my code
  - [ ] If it is a core feature, I have added thorough tests
  - [ ] Do we need to implement analytics?
  - [ ] Will this be part of a product update? If yes, please write one phrase about this update
  EOT
  file                = ".github/pull_request_template.md"
  repository          = var.repository_name
  overwrite_on_create = true
  branch              = each.key
}

resource "github_repository_file" "codeowners_main" {
  content             = <<EOT
  * @softservedata
  EOT
  file                = "CODEOWNERS"
  repository          = var.repository_name
  branch              = "main"
  overwrite_on_create = true
}

# Вебхук для Discord
resource "null_resource" "discord_webhook" {
  triggers = {
    # Тут ви можете вказати тригери для оновлення вебхуку, якщо потрібно
  }

  provisioner "local-exec" {
    command = <<-EOT
      curl -X POST -H "Content-Type: application/json" -d '{
        "content": "Hello from Terraform!",
        "username": "Spidey Bot"
      }' https://discordapp.com/api/webhooks/1160090398123900979/n9AkJsxD_w23TToQ8AUqhJxEW1ibFeT1gFELLMwmUrFtlYJSCBD2BJyTQW0PEGJoKvgh
    EOT
  }
}

resource "github_actions_secret" "pat" {
  repository      = var.repository_name
  secret_name     = "PAT"
  plaintext_value = var.action_token
}

