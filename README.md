
## Introduction

The current repository contains the terraform files and ADO yaml pipeline to deploy the following scenario:

https://learn.microsoft.com/en-us/azure/architecture/solution-ideas/articles/scalable-web-and-mobile-applications-using-azure-database-for-postgresql#architecture

## Architecture goals and how they are completed


  ### A browser or mobile app makes requests for resources from the API.
   For this the decision was to implement Private endpoint access for both the WebApp and the PostgreSQL server 
  ### The requests are transmitted using HTTPS with TLS termination, which is handled by Azure App Services.
   HTTPS access-only is enabled on the Web App. Custom domain certificate needs to be added after the deployment.
  ### Azure App Services handles API requests, and it can be scaled up or scaled out to handle the changing demand.
   To accomplish the scale-up and scale-out we are choosing a service plan tier that can support the scaling - B1 in our case
  ### Azure Database for PostgreSQL provides a relational database service that's based on the open-source Postgres database engine. Use Hyperscale (Citus) or Flexible Server (Preview) deployment modes for highly scalable databases.
   For highly-scalable option, we are going with Flexible Server

## Repository structure
### File structure

| File/Folder  | Description |
| ------------- | ------------- |
| terraform  | general terraform folder  |
| terraform/deploy-infra  | folder,containing the terraform files  |
| terraform/deploy-infra/backend.tf  | backend file  |
| terraform/deploy-infra/main.tf  | core file,defining the code of the resources  |
| terraform/deploy-infra/variables.tf  | file defining variable blocks for their types and descriptions  |
| terraform/deploy-infra/vars.tfvars  | tfvars file, containing variable definitions  |
| 1_job.txt  | log file from ADO, that contains the output of successful deployment from ADO to Azure Cloud  |
| README.md  | readme file  |
| deploy-tf.yml  | YAML pipeline file  |
