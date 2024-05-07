# terraform_aks_multi_region

This Project was for a Challange to buld Multi Region AKS Scenario using the Global Azure Traffic Manager to manage requests.
I should Deploy Ingress and a Hello World Application using Helm and add a auto scaling on CPU usage.
I should use a automation langurage for IAC of my Choice.
I set me a Timelimit og 8 Hours.



![Architecture](architecture.png?raw=true "Title")

Technical Debts: 
- The Static IP I create with TF not connect to the Cluster.
- That means any time the Infastructure is build up from Scratch there is the manuel Task to change the IP Adresses that added to the Traffic Manger one Time manuel.

Future Tasks:
- Crete a TF Modul for the AKS.
- Create a TF Modul for Traffic Manager.
- Setup GitHub Action Pipeline for Deployment.
- Add Sonarqube Snyk or other Security Tools.
- Limit Access to Kubernetes api using ZeroTrust. (Or Bastion)
- Fix Technical Debt terraform_aks_multi_region
