
# Introduction 
This is an example of deploying an IoT Application using Azure IoT PaaS components

# Getting Started
---
## Before Deploy
1. Create environments and variable groups and put in your variable data (i.e. subscription info, desired app name, etc.)
2. Create/purchase a root certificate and have the ability to create a leaf certificate for your devices
3. [Manual process in step 5...?] Put the B64 encoded value from the .pem file into the iothubdps.bicep file in the dpsGroupCertificate resource so that it gets registered when the DPS is created

---
## Deploy Resources
4. Create an Azure Dev Ops job to run the Deploy_Infrastructure.yml YAML file to create the resources and execute the job, granting permissions as needed to your subscription.

---
## After Deploy
5. Navigate to the DPS and create an enrollment group based on the device-root-cert that was deployed in step 3. 
(this is still not available in ARM templates... maybe could do it in Powershell...?)

---
## Deploy the applications
6.  Deploy the Function App and Website
7.  Start the Function App, Website, and Stream Analytics

---
## Start running the application
8.	Use the Simulator to stream data to the IoT Hub! If using certificate authentication with the DPS, you will need to edit the DPS scope id in the config file.

