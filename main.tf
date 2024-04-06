terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.27.0"
    }
  }
}

provider "azurerm" {
  features {}
}

variable "location_region1" {
  default = "West Europe"
}

variable "resource_group_name_region1" {
  default = "my-aks-rg-region1"
}

variable "node_resource_group_name_region1" {
  default = "my-aks-rg-region1-nodes"
}

variable "location_region2" {
  default = "North Europe"
}

variable "resource_group_name_region2" {
  default = "my-aks-rg-region2"
}

variable "node_resource_group_name_region2" {
  default = "my-aks-rg-region2-nodes"
}

variable "vm_size" {
  default = "Standard_D2_v2"
}

variable "resource_group_name_prefix" {
  default = "k8s-cluster"
}

variable "resource_group_location" {
  default = "North Europe"
}

resource "azurerm_resource_group" "resource_group_region1" {
  name     = var.resource_group_name_region1
  location = var.location_region1
  tags = {
    author  = "Philipp.Homberger@gmail.com"
    Purpose = "Testing"
  }
}

resource "azurerm_resource_group" "resource_group_region2" {
  name     = var.resource_group_name_region2
  location = var.location_region2
  tags = {
    author  = "Philipp.Homberger@gmail.com"
    Purpose = "Testing"
  }
}
resource "azurerm_kubernetes_cluster" "server_cluster_region1" {
  name                = "server_cluster"
  location            = azurerm_resource_group.resource_group_region1.location
  resource_group_name = azurerm_resource_group.resource_group_region1.name
  node_resource_group = var.node_resource_group_name_region1
  dns_prefix          = "fixit"
  #kubernetes_version = var.kubernetes_version

  default_node_pool {
    name       = "default"
    #node_count = 1
    min_count  = 3
    max_count  = 9
    vm_size    = var.vm_size

    type                   = "VirtualMachineScaleSets"
    enable_auto_scaling    = true
    enable_host_encryption = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    Author      = "Philipp Homberger"
    Purpose     = "Testing"
  }


  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "basic"

  }
  http_application_routing_enabled = false
  depends_on = [
    azurerm_resource_group.resource_group_region1
  ]
}

resource "azurerm_public_ip" "public-ip-region1" {
  name                = "fixit-public-ip"
  location            = var.location_region1
  resource_group_name = var.node_resource_group_name_region1
  allocation_method   = "Static"
  domain_name_label   = "fixit"

  depends_on = [
    azurerm_kubernetes_cluster.server_cluster_region1
  ]
}

resource "azurerm_kubernetes_cluster" "server_cluster_region2" {
  name                = "server_cluster"
  location            = azurerm_resource_group.resource_group_region2.location
  resource_group_name = azurerm_resource_group.resource_group_region2.name
  node_resource_group = var.node_resource_group_name_region2
  dns_prefix          = "fixit"
  #kubernetes_version = var.kubernetes_version

  default_node_pool {
    name       = "default"
    #node_count = 1
    min_count  = 3
    max_count  = 9
    vm_size    = var.vm_size

    type                   = "VirtualMachineScaleSets"
    enable_auto_scaling    = true
    enable_host_encryption = false
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Production"
    Purpose     = "Testing"
  }


  network_profile {
    network_plugin    = "kubenet"
    load_balancer_sku = "basic"

  }
  http_application_routing_enabled = false
  depends_on = [
    azurerm_resource_group.resource_group_region2
  ]
}

resource "azurerm_public_ip" "public-ip-region2" {
  name                = "fixit-public-ip"
  location            = var.location_region2
  resource_group_name = var.node_resource_group_name_region2
  allocation_method   = "Static"
  domain_name_label   = "fixit"

  depends_on = [
    azurerm_kubernetes_cluster.server_cluster_region2
  ]
}

provider "helm" {
  alias = "region1"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  alias                  = "region1"
  host                   = azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.server_cluster_region1.kube_config.0.cluster_ca_certificate)
  #load_config_file       = false
}

provider "helm" {
  alias = "region2"
  kubernetes {
    host                   = azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.cluster_ca_certificate)
  }
}

provider "kubernetes" {
  alias                  = "region2"
  host                   = azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.host
  client_certificate     = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.server_cluster_region2.kube_config.0.cluster_ca_certificate)
}


resource "helm_release" "nginx_region1" {
  provider   = helm.region1
  name       = "ingress-nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  namespace  = "default"

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-internal"
    value = "true"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.public-ip-region1.ip_address
  }

  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }
}

resource "helm_release" "nginx_region2" {
  provider   = helm.region2
  name       = "ingress-nginx"
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "nginx-ingress-controller"
  namespace  = "default"

  set {
    name  = "controller.service.externalTrafficPolicy"
    value = "Local"
  }

  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-internal"
    value = "true"
  }

  set {
    name  = "controller.service.loadBalancerIP"
    value = azurerm_public_ip.public-ip-region2.ip_address
  }

  set {
    name  = "controller.service.annotations.service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path"
    value = "/healthz"
  }
}


resource "helm_release" "hello_world_region1" {
  provider = helm.region1
  name     = "hello"
  #repository = "https://azure-samples.github.io/helm-charts/"
  chart     = "./hello-kubernetes"
  namespace = "default"
}

resource "helm_release" "hello_world_region2" {
  provider = helm.region2
  name     = "hello"
  #repository = "https://azure-samples.github.io/helm-charts/"
  chart     = "./hello-kubernetes"
  namespace = "default"
}

resource "helm_release" "kubeshark_region1" {
  provider   = helm.region1
  name       = "kubeshark"
  repository = "https://helm.kubeshark.co"
  chart      = "kubeshark"
  namespace  = "default"
}

resource "helm_release" "kubeshark_region2" {
  provider   = helm.region2
  name       = "kubeshark"
  repository = "https://helm.kubeshark.co"
  chart      = "kubeshark"
  namespace  = "default"
}

resource "kubernetes_ingress_v1" "region1" {
  provider = kubernetes.region1
  metadata {
    name      = "aks-hello"
    namespace = "default"
    labels = {
      name = "front-end"
    }
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" : "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" : "true"
    }
  }

  spec {
    rule {
      host = "${random_string.azurerm_traffic_manager_profile_dns_config_relative_name.result}.trafficmanager.net"
      http {
        path {
          backend {
            service {
              name = "hello-kubernetes-hello"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress_v1" "region2" {
  provider = kubernetes.region2
  metadata {
    name      = "aks-hello"
    namespace = "default"
    labels = {
      name = "front-end"
    }
    annotations = {
      "kubernetes.io/ingress.class" : "nginx"
      "nginx.ingress.kubernetes.io/ssl-redirect" : "true"
      "nginx.ingress.kubernetes.io/force-ssl-redirect" : "true"
    }
  }

  spec {
    rule {
      host = "${random_string.azurerm_traffic_manager_profile_dns_config_relative_name.result}.trafficmanager.net"
      http {
        path {
          backend {
            service {
              name = "hello-kubernetes-hello"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }
}

resource "random_pet" "rg_name" {
  prefix = var.resource_group_name_prefix
}

resource "azurerm_resource_group" "rg" {
  name     = random_pet.rg_name.id
  location = var.resource_group_location
  tags = {
    Author  = "Philipp.Homberger@gmail.com"
    Purpose = "Testing"
  }
}

resource "random_string" "azurerm_traffic_manager_profile_name" {
  length  = 25
  upper   = false
  numeric = false
  special = false
}

resource "random_string" "azurerm_traffic_manager_profile_dns_config_relative_name" {
  length  = 10
  upper   = false
  numeric = false
  special = false
}

resource "azurerm_traffic_manager_profile" "profile" {
  name                   = random_string.azurerm_traffic_manager_profile_name.result
  resource_group_name    = azurerm_resource_group.rg.name
  traffic_routing_method = "Performance"
  dns_config {
    relative_name = random_string.azurerm_traffic_manager_profile_dns_config_relative_name.result
    ttl           = 30
  }

  monitor_config {
    protocol                    = "HTTPS"
    port                        = 443
    path                        = "/"
    expected_status_code_ranges = ["200-202", "301-302"]
  }
}

resource "azurerm_traffic_manager_external_endpoint" "endpoint1" {
  profile_id        = azurerm_traffic_manager_profile.profile.id
  name              = "endpoint1"
  target            = "20.160.1.48"
  endpoint_location = "West Europe"
  weight            = 50
}

resource "azurerm_traffic_manager_external_endpoint" "endpoint2" {
  profile_id        = azurerm_traffic_manager_profile.profile.id
  name              = "endpoint2"
  target            = "52.178.190.111"
  endpoint_location = "North Europe"
  weight            = 50
}
