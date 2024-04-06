# terraform_aks_multi_region

This Project Create a Multi Region AKS Scenario using Azure Traffic Manager to manage requests.

Technical Deps: 
- The Static IP I create with TF not connect to the Cluster.
- That means any time the Infastructure is build up from Scratch there is the manuel Task to change the IP Adresses that added to the Traffic Manger one Time manuel.


Future Tasks:
- Crete a TF Modul for the AKS.
- Create a TF Modul for Traffic Manager.
- Setup GitHub Action Pipeline for Deployment. 
- Limit Access to Kubernetes api using ZeroTrust. (Or Bastion)
- Fix Technical Deb