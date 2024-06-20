#!/bin/bash
#

# for eash of override - key/value pairs for constants - shared by all scripts


usage() {
  cat <<EOF
Usage: $0 [PARAMs]
example 
EOF
}

source ./vars.sh


deployment() {

  echo "Date: $(date)"
  echo "Timestamp: $(date +%s)"
  echo "$UNIQUE"
  echo "running with create=${CREATE_PROJ} delete=${DELETE_PROJ} boot_project_id=${BOOT_PROJECT_ID}"

if [[ "$CREATE_PROJ" != false ]]; then
  # linux
  STREAM_PROJECT_RAND=$(shuf -i 0-10000 -n 1)
  # osx
  #STREAM_PROJECT_RAND=$(jot -r 1 1000 10000)
  STREAM_PROJECT_ID=${STREAM_PROJECT_NAME_PREFIX}-${STREAM_PROJECT_RAND}
  echo "Creating project: $STREAM_PROJECT_ID"
else
  #STREAM_PROJECT_ID=${STREAM_PROJECT_ID_PASSED}
  echo "Reusing project: $STREAM_PROJECT_ID"
fi

echo "STREAM_PROJECT_ID: $STREAM_PROJECT_ID"


if [[ "$CREATE_PROJ" != false ]]; then
  # create project
  gcloud config set project "${BOOT_PROJECT_ID}"
  BILLING_FORMAT="--format=value(billingAccountName)"
  BILLING_ID=$(gcloud billing projects describe $BOOT_PROJECT_ID $BILLING_FORMAT | sed 's/.*\///')
  ORG_ID=$(gcloud projects get-ancestors $BOOT_PROJECT_ID --format='get(id)' | tail -1)
  #EMAIL=$(gcloud config list --format json|jq .core.account | sed 's/"//g')
  EMAIL=$SUPER_ADMIN_EMAIL

  echo "Creating project: ${STREAM_PROJECT_ID} on folder: ${ROOT_FOLDER_ID}"
  gcloud projects create "$STREAM_PROJECT_ID" --name="${STREAM_PROJECT_ID}" --set-as-default --folder="$ROOT_FOLDER_ID"

  gcloud beta billing projects link "${STREAM_PROJECT_ID}" --billing-account "${BILLING_ID}"  
  gcloud config set project "${STREAM_PROJECT_ID}"

  
  # service account

  # iam roles for user

  # iam roles for service account
  
  # project services enablement
  ## set by billing association usually
  gcloud services enable cloudapis.googleapis.com
  gcloud services enable cloudfunctions.googleapis.com
  gcloud services enable run.googleapis.com
  gcloud services enable cloudbuild.googleapis.com
  gcloud services enable artifactregistry.googleapis.com
  gcloud services enable pubsub.googleapis.com



  # create bucket

  # create cloud function

  # BQ schema
  
  # Logging
 


fi


# The service account running this build does not have permission to write logs. To fix this, grant the Logs Writer (roles/logging.logWriter) role to the service account.
# set roles/logging.logWriter on project id service account - -compute@developer.gserviceaccount.com

 PROJECT_NUMBER=$(gcloud projects list --filter="${STREAM_PROJECT_ID}" '--format=value(PROJECT_NUMBER)')
 echo "PROJECT_NUMBER: $PROJECT_NUMBER"
 SA_EMAIL=$PROJECT_NUMBER-compute@developer.gserviceaccount.com
 echo "bind $SA_EMAIL"
 #gcloud organizations add-iam-policy-binding "${ORG_ID}" --member="serviceAccount:${SA_EMAIL}" --role=roles/logging.logWriter --condition=None --quiet
 
 #echo "wait 60 sec"
 #sleep 60
# /deployment.sh -c false -d false -p true -b eventstream-biometric-old -s eventstream-biometric-3732
if [[ "$PROVISION_PROJ" != false ]]; then
#cd main/java/functions
  echo "provisioning to ${STREAM_PROJECT_ID}"
  gcloud functions deploy ${HTTP_FUNCTION_NAME} \
--gen2 \
--allow-unauthenticated \
--runtime=java17 \
--region=us-central1 \
--source=. \
--entry-point=${JAVA_FQ_CLASSNAME} \
--memory=512MB \
--trigger-http 

#cd ../../../

fi



if [[ "$DELETE_PROJ" != false ]]; then
  # disable billing before deletion - to preserve the project/billing quota
  gcloud alpha billing projects unlink "${STREAM_PROJECT_ID}"
  # delete cc project
  gcloud projects delete "$STREAM_PROJECT_ID" --quiet
fi



  # RETURN
  gcloud config set project "${BOOT_PROJECT_ID}"  


  end=`date +%s`
  runtime=$((end-start))
  echo "Total Duration: ${runtime} sec"
  echo "Date: $(date)"
  echo "Timestamp: $(date +%s)"
}

UNIQUE=old
CREATE_PROJ=false
DELETE_PROJ=false
PROVISION_PROJ=false
STREAM_PROJECT_ID=
BOOT_PROJECT_ID=
while getopts ":c:d:b:p:s:u:" PARAM; do
  case $PARAM in
    c)
      CREATE_PROJ=${OPTARG}
      ;;
    d)
      DELETE_PROJ=${OPTARG}
      ;;
    p)
      PROVISION_PROJ=${OPTARG}
      ;;
    b)
      BOOT_PROJECT_ID=${OPTARG}
      ;;
    s)
      STREAM_PROJECT_ID=${OPTARG}
      ;;
    ?)
      usage
      exit
      ;;
  esac
done

#  echo "Options are: -c true/false (create) -d true/false (delete proj) -b BOOT_PROJ_ID"


if [[ -z $UNIQUE ]]; then
  usage
  exit 1
fi

echo "existing project: $PROJECT_ID"
deployment "$CREATE_PROJ" "$DELETE_PROJ" "$PROVISION_PROJ" "$BOOT_PROJECT_ID" "$STREAM_PROJECT_ID"
printf "**** Done ****\n"
