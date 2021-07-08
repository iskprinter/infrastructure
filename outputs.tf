// Begin Official Jenkins-X content

output "connect" {
  description = "Connect to cluster"
  value       = module.infrastructure.connect
}

output "follow_install_logs" {
  description = "Follow Jenkins X install logs"
  value       = "jx admin log"
}

output "docs" {
  description = "Follow Jenkins X 3.x alpha docs for more information"
  value       = "https://jenkins-x.io/v3/"
}

// End Official Jenkins-X content
