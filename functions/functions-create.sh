# There are 2 actions that need to be created and 2 triggers (or 1 if you just want to trigger by hand)
# 
# Docker image
#
# The runtimes for both actions are performed from a Docker image. This is because we need to perform a terraform 
# action via the IBM Schematics CLI. This is actually easier than using a python script, for example, and using the 
# Schematics API. 
#
# If you look at the Dockerfile, it uses a base openwhisk image bulit for using docker images as functions actions.
# The Dockerfile also installs the IBM Cloud CLI and the Schematics plugin
#
# The exec file is the script that actually gets run when the action is invoked. It takes 3 parameters, which will
# be given to the trigger to action to pass in when invoked.
#
# The docker image must be built and pushed to Docker Hub.
# Login to Docker Hub, build and push the image to Docker Hub from the directory containing the Dockerfile
docker login -u <username> -p <password>
docker build -t <dockerhub-username>/<repo-name>:<tag> .
docker push <dockerhub-username>/<repo-name>:<tag>

# ----------------------------------------------------------
# The following steps create the various Cloud functions actions, triggers, and rules
# Prerequisites:
#  (1) IBM Cloud CLI is installed and included in PATH
#  (2) IBM Cloud Functions plugin is installed
#  (3) A Cloud Object Storage instance was provisioned
#  (4) A regional bucket was created in the Cloud Object Storage instance
# ----------------------------------------------------------

# ----------------------------------------------------------
# Replace the TODO sections with your values
# ----------------------------------------------------------

# Get an IBM Cloud API key. It is needed by the functions action to use the IBM Cloud CLI
IBMCLOUD_API_KEY=<TODO-your-ibm-cloud-api-key>

# Cloud Object Storage instance name
COS_INSTANCE_NAME=<TODO-cos-instance-name>
# Regional bucket in above Cloud Object Storage instance. Note that the bucket needs to be regional and in the same
# region as the cloud functions workspace.
BUCKET_NAME=<TODO-your-bucket-name>

# The ID of the Schematics workspace
SCHEMATICS_WORKSPACE_ID=<TODO-schematics-workspace-id>

# Cloud Functions namespace where the tutorial application
# entities will be created
FUNCTIONS_NAMESPACE_NAME=<TODO-functions-namespace>

# ------------------------------------------------------------
# Create Cloud Functions elements
# ------------------------------------------------------------

# Create and set namespace
ibmcloud fn namespace create $FUNCTIONS_NAMESPACE_NAME --description "Drive Schematics"
ibmcloud fn property set --namespace $FUNCTIONS_NAMESPACE_NAME

# List namespaces and entities in the current namespace
ibmcloud fn namespace list
ibmcloud fn list

# Prepare namespace for Cloud Object Storage triggers. This command authenticates the cloud functions namespace to 
# manage COS bucket event triggers
ibmcloud iam authorization-policy-create functions cloud_object_storage "Notifications Manager" --source-service-instance-name $FUNCTIONS_NAMESPACE_NAME --target-service-instance-name $COS_INSTANCE_NAME

# Create trigger that fires when anything is uploaded to the specified bucket
ibmcloud fn trigger create bucket_write_trigger --feed /whisk.system/cos/changes --param bucket $BUCKET_NAME --param event_types write
# Display trigger properties
ibmcloud fn trigger get bucket_write_trigger

# Create trigger that fires on a timer to kick off the run. This one will run every Monday at noon
# >>>>>> Do not create this if you want to manually invoke the action <<<<<<<<<
ibmcloud fn trigger create every_monday_trigger --feed /whisk.system/alarms/alarm --param cron "0 12 * * 1"
# Display trigger properties
ibmcloud fn trigger get every_monday_trigger

# Create a package and display its properties
ibmcloud fn package create manage_env
ibmcloud fn package get manage_env

# Create an action that applies the terraform template to create the environment and run the workload
# Also need to pass the 3 parameters to the action
# replace your docker image details
ibmcloud fn action update manage_env/applyvpc --docker <dockerhub-username>/<repo-name>:<tag> --param IBMCLOUD_API_KEY $IBMCLOUD_API_KEY --param WORKSPACE_ID $SCHEMATICS_WORKSPACE_ID --param ACTION apply
# Display the action's properties
ibmcloud fn action get manage_env/applyvpc

# Create an action that destroys the terraform template to create the environment and run the workload
# Also need to pass the 3 parameters to the action
# replace your docker image details
ibmcloud fn action update manage_env/destroyvpc --docker <dockerhub-username>/<repo-name>:<tag> --param IBMCLOUD_API_KEY $IBMCLOUD_API_KEY --param WORKSPACE_ID $SCHEMATICS_WORKSPACE_ID --param ACTION destroy
# Display the action's properties
ibmcloud fn action get manage_env/destroyvpc

# Create a rule that associates the cron timer trigger with the apply vpc action
ibmcloud fn rule create cron_timer_rule every_monday_trigger manage_env/applyvpc
ibmcloud fn rule get cron_timer_rule

# Create a rule that associates the bucket write trigger with the destroy vpc action
ibmcloud fn rule create bucket_write_rule bucket_write_trigger manage_env/destroyvpc
ibmcloud fn rule get bucket_write_rule

# Display entities in the current namespace
ibmcloud fn list