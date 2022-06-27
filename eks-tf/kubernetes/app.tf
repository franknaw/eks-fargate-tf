resource "kubernetes_namespace" "namespace" {
  metadata {
    name   = var.namespace
    labels = var.labels
  }
  depends_on = [var.namespace_depends_on]
}


resource "kubernetes_ingress" "range-ingress" {
  metadata {
    name      = "${var.deployment_name}-ingress"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    annotations = {
      "kubernetes.io/ingress.class"           = "alb"
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    }
    labels = var.labels
  }

  spec {
    backend {
      service_name = kubernetes_service.landing_page_service.metadata[0].name
      service_port = kubernetes_service.landing_page_service.spec[0].port[0].port
    }

    rule {
      http {
        path {
          path = "/range1/*"
          backend {
            service_name = kubernetes_service.range1_service.metadata[0].name
            service_port = kubernetes_service.range1_service.spec[0].port[0].port
          }
        }

        path {
          path = "/range2*"
          backend {
            service_name = kubernetes_service.range2_service.metadata[0].name
            service_port = kubernetes_service.range2_service.spec[0].port[0].port
          }
        }
      }
    }
  }

  wait_for_load_balancer = true
  depends_on             = [kubernetes_service.landing_page_service, kubernetes_service.range1_service, kubernetes_service.range2_service, helm_release.helm_alb]
}


data "aws_ecr_repository" "landing_page-repo" {
  name = "landing-page"
}

output "landing_page-repo" {
  value = data.aws_ecr_repository.landing_page-repo.repository_url
}

data "aws_ecr_image" "landing_page-image" {
  repository_name = data.aws_ecr_repository.landing_page-repo.name
  image_tag       = "latest"
}

output "landing_page-image" {
  value = data.aws_ecr_image.landing_page-image.image_digest
}

resource "kubernetes_deployment" "landing_page_deploy" {
  metadata {
    name      = "landing-page-${terraform.workspace}"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = var.labels
    }

    template {
      metadata {
        labels = var.labels
      }

      spec {
        container {
          image = "${data.aws_ecr_repository.landing_page-repo.repository_url}:${data.aws_ecr_image.landing_page-image.image_tag}@${data.aws_ecr_image.landing_page-image.image_digest}"
          name  = "landing-page"
          port {
            name           = "landing-page"
            container_port = 8080
          }

        }

      }
    }
  }
}

resource "kubernetes_service" "landing_page_service" {
  metadata {
    name      = "landing-page-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.labels
  }
  spec {
    selector = var.labels
    type     = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
  depends_on = [kubernetes_deployment.landing_page_deploy]
}



data "aws_ecr_repository" "range-micro-1-repo" {
  name = "range-micro-1"
}

output "range-micro-1-repo" {
  value = data.aws_ecr_repository.range-micro-1-repo.repository_url
}

data "aws_ecr_image" "range-micro-1-image" {
  repository_name = data.aws_ecr_repository.range-micro-1-repo.name
  image_tag       = "latest"
}

output "range-micro-1-image" {
  value = data.aws_ecr_image.range-micro-1-image.image_digest
}


resource "kubernetes_deployment" "range1_deploy" {
  metadata {
    name      = "range1-${terraform.workspace}"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = var.labels
    }

    template {
      metadata {
        labels = var.labels
      }

      spec {
        container {
          image = "${data.aws_ecr_repository.range-micro-1-repo.repository_url}:${data.aws_ecr_image.range-micro-1-image.image_tag}@${data.aws_ecr_image.range-micro-1-image.image_digest}"
          name  = "range-micro-1"
          port {
            name           = "range-micro-1"
            container_port = 8080
          }

        }
      }
    }
  }
}

resource "kubernetes_service" "range1_service" {
  metadata {
    name      = "range1-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.labels
  }
  spec {
    selector = var.labels
    type     = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
  depends_on = [kubernetes_deployment.range1_deploy]
}

data "aws_ecr_repository" "range-micro-2-repo" {
  name = "range-micro-2"
}

output "range-micro-2-repo" {
  value = data.aws_ecr_repository.range-micro-2-repo.repository_url
}

data "aws_ecr_image" "range-micro-2-image" {
  repository_name = data.aws_ecr_repository.range-micro-2-repo.name
  image_tag       = "latest"
}

output "range-micro-2-image" {
  value = data.aws_ecr_image.range-micro-2-image.image_digest
}


resource "kubernetes_deployment" "range2_deploy" {
  metadata {
    name      = "range2-${terraform.workspace}"
    namespace = kubernetes_namespace.namespace.metadata[0].name
    labels    = var.labels
  }

  spec {
    replicas = var.replicas

    selector {
      match_labels = var.labels
    }

    template {
      metadata {
        labels = var.labels
      }

      spec {
        container {
          image = "${data.aws_ecr_repository.range-micro-2-repo.repository_url}:${data.aws_ecr_image.range-micro-2-image.image_tag}@${data.aws_ecr_image.range-micro-2-image.image_digest}"
          name  = "range-micro-2"
          port {
            name           = "range-micro-2"
            container_port = 8080
          }

          readiness_probe {
            http_get {
              path = "/health"
              port = 8080
            }

            initial_delay_seconds = 3
            period_seconds        = 3
          }

        }
      }
    }
  }
}

resource "kubernetes_service" "range2_service" {
  metadata {
    name      = "range2-service"
    namespace = kubernetes_namespace.namespace.metadata[0].name
     labels = var.labels
  }
  spec {
    selector = var.labels
    type     = "NodePort"
    port {
      port        = 8080
      target_port = 8080
      protocol    = "TCP"
    }
  }
  depends_on = [kubernetes_deployment.range2_deploy]
}

