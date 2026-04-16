# EWU-CSCD396-2023-Fall

## Assignment 2 - DRAFT!!!

The purpose of this assignment is to solidify your learning of:

- Build and deploying containers
- Terraform IaC
- Fnctions and Logic Apps
- Messaging and Eventing

## Prerequisites

- Install VSCode Extension 'Azure App Service'

## Instructions

- All cloud infrastructure should be built with Terraform. Terraform State should be maintained in a Storage Account
- All services should be deployed through a GitHub Action workflow

Complete the following Tutorials and do not clean up resources until assignment is graded.

1. Create and deploy a containerized Web App

   {https://learn.microsoft.com/en-us/azure/app-service/quickstart-dotnetcore?tabs=net70&pivots=development-environment-cli}
   Note: Deploy application code using az cli, not the VSCode extension

- Container App Created ❌✅
  (You can use the below steps to publish your app)

  - Create a new app using dotnet new command 
  - See docs/containers.md for how to create and deploy an image of your new app code to azure container registry
  - Create a terraform main.tf and variables.tf files within a terraform folder. These files should contain relevant HCL for deploying a container app. 
  - Use a variable for the container image name
  - Create a workflow that deploys your container app with Terraform using the init, plan, and apply commands

- Url Accessible (and working) ❌✅
- Successful Workflow Run to Deploy Infrastructure ❌✅

2. Create and deploy an Auzre Function Bound to Service Bus. The function should write messages received to a storage account

   {https://learn.microsoft.com/en-us/azure/app-service/scenario-secure-app-access-storage?tabs=azure-cli}

- Enabled Managed Identity on Web App ❌✅
- Created Storage Account ❌✅
- Web App Granted Access to Storage Account ❌✅

3. Add a feature to the web app to write a message to the Service Bus from step 2. Ideally this ia a text box for the message and a button to submit the message to the bus. You can use the Azure SDK for .NET to send messages to the bus from your web app.




4. Create a PowerShell script called Assignment2.ps1 on your branch within the Assignment2 folder ❌✅

- Copy the following text into your PowerShell script and fill in your specific values for the variables
```
$SubscriptionId = ""
$ResourceGroup = ""
$WebAppName = ""
$WebAppUrl = ""
$KeyVault = ""
$SecretName = ""
$StorageAccount = ""
```
- You can test if your assignment will pass by running the PS script at Scripts/Assignment2Grading.ps1. Run your Assignment2.ps1 script to set local variables first.

5. Please add jcurry9@ewu.edu as a contributor to your subscription, otherwise grading will not be possible.


## Extra Credit

- Have the web app write the message to an Azure SQL Table in addition to the message bus
- 
