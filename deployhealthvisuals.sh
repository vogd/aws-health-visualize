#!/bin/bash

#-----------------Define variables
datasourceID="7916cf11-3461-4cf8-9961-3f3fb5a47a2d-V3"
datasetID="ce041082-79a5-4788-b2a1-95b8fde26a5d-V3"
dashboardID="df691782-869e-4a9d-a170-5bbfa1537f23-V3"


definevarFunction()
{
   echo ""

   AccountVariable=$(echo $(aws sts get-caller-identity)|awk -F ',' '{print$2}'| grep  -o -E '[0-9]+');
   BucketVariable=$(echo $(aws cloudformation describe-stacks --query Stacks[].Parameters[*] --output text | grep "S3BucketNameforHealthData"| awk -F " " '{print$2}'))
    if [ "$BucketVariable" = "" ]; then
       # $var is empty
       echo "Bucket name can not be found. Please specify the bucket via command line, or check the health visualization stack is deployed in correct region"
       exit 1
    fi
   echo " "
   echo " " 
   echo -e "\t-accountid " $AccountVariable " taken from current shell using cli"
   echo -e "\t-bucketname " $BucketVariable "taken from current account stack with parameter S3BucketNameforHealthData"
#   exit 1 # Exit script after printing data
}

# ----------------Confirm parameters provided during execution
while getopts ":a:b:" opt; do
  case $opt in
     a)
       echo "argument -accountid called with parameter $OPTARG" >&2
       AccountVariable="$OPTARG"
       ;;
     b)
       echo "argument -bucketname called with parameter $OPTARG" >&2
       BucketVariable="$OPTARG"
       ;;
     *)
       echo "invalid command: no accountid -a and bucketname -b parameter included with argument $OPTARG"
       ;;
  esac
done

# ----------------Call definevarFunction to get the vars from emv in case parameters are empty
if [ -z "$AccountVariable" ] || [ -z "$BucketVariable" ] 
then
   echo "No accountid -a xxxx and bucketname -b yyyy  parameters set. Taking from environment";
   definevarFunction
fi

#echo "$AccountVariable"
#echo "$BucketVariable"


# ----------------Get current QuickSight account region and namespace
   # AWSRegion=$(aws configure get region)
#---QuickSight account can be created in different region than default aws environment region
   QSnamespace=$(echo $(aws quicksight describe-account-settings --aws-account-id $AccountVariable|grep -i namespace|awk -F ":" '{print$2}'|awk -F '"' '{print$2}'))
   echo "Default Quicksight namespace is " $QSnamespace
   QSUser=$(echo $(aws quicksight list-users --aws-account-id $AccountVariable --namespace $QSnamespace|grep "UserName" |awk -F '"' '{print$4}'))
   QSuserARN=$(echo $(aws quicksight list-users --aws-account-id $AccountVariable --namespace $QSnamespace|grep "arn:aws"|awk -F '"' '{print$4}'))
   QSRegion=$(echo $QSuserARN|awk -F ":" '{print$4}')
   echo "QuickSight account created in region " $QSRegion
   echo " "
   echo " "
#-----------------Prepare dashboard templates 
preparetemplate ()  
{
   sed "s|AccountVariable|$3|g" $1>$2
   sed -i bak "s|BucketVariable|$4|g" $2
   sed -i bak "s|QSRegion|$5|g" $2
   sed -i bak "s|QSUser|$6|g" $2 
   echo "Template "$2" updated with " $(echo $(egrep "AwsAccountId|BucketVariable|DataSourceArn|Principal" $2))
   echo ""
}

# ----------------Deploy Dashboard
deploydatasource()
{
  echo ".Step1"
  echo "Deploying DataSource......"
  echo $(aws quicksight create-data-source --cli-input-json file://$1 --aws-account-id $2 --region $3)
    echo " "
    echo "Verify datasource status...."
          sleep 5
          datasourceStatus=$(echo$(aws quicksight describe-data-source --aws-account-id $2 --data-source-id $4 --region $3|grep Status))
    if [[ $datasourceStatus != *"CREATION_SUCCESSFUL"* ]]
    then
        echo "Failed to create datasource. Check status of --data-source-id "$4
          exit 1
          else
          echo $datasourceStatus
    fi
}

deploydataset()
{
   echo ".Step2"
   echo "Deploying Data-Set......."
   echo $(aws quicksight create-data-set --cli-input-json file://"$1" --aws-account-id $2 --region $3)
     echo " "
     echo "Verify data-set status...."
           sleep 5
           datasetStatus=$(echo$(aws quicksight describe-data-set --aws-account-id $2 --data-set-id $4 --region $3|grep Status))
     if [[ $datasetStatus != *"200"* ]]
     then
         echo "Failed to create data-set. Check status of --data-set-id "$4
           exit 1
           else
           echo "SUCCESSFUL - "$datasetStatus
     fi
}

deploydashboard()
{
   echo ".Step3"
   echo "Deploying Dashboard......."
   echo $(aws quicksight create-dashboard --cli-input-json file://"$1")
     echo " "
     echo "Verify dashboard status...."
           sleep 5
           dashboardStatus=$(echo$(aws quicksight describe-dashboard --aws-account-id $2 --dashboard-id $4 --region $3|grep Status))
     if [[ $dashboardStatus != *"200"* ]]
     then
         echo "Failed to deploy dashboard. Check status of --dashboard-id "$4
           exit 1
           else
           echo "SUCCESSFUL - "$dashboardStatus
     fi
}

# ----------------Confirm source templates exist before execution
templates=(./source-templates/datasourcetemplate.json ./source-templates/datasettemplate.json ./source-templates/dashboard-template.json)
for SOURCEFILE in ${templates[@]}
do
  if [[ ! -f $SOURCEFILE ]]
  then
    echo "The file ${SOURCEFILE} does not exist!"
    exit 1 # Exit script after failure to find sources
  else

    #---------------Apply template modifications
    filename=$(echo ${SOURCEFILE}|awk -F "/" '{print$NF}') 
    preparetemplate "${SOURCEFILE}" "./create-$filename" "$AccountVariable" "$BucketVariable" "$QSRegion" "$QSUser"

    #---------------Call deployment stack referring template vars
       if [[ $filename == *"datasourcetemplate"* ]]
       then
          deploydatasource "./create-$filename" "$AccountVariable" "$QSRegion" $datasourceID
       elif [[ $filename == *"datasettemplate"* ]]  
       then  
          deploydataset "./create-$filename" "$AccountVariable" "$QSRegion" $datasetID
       else 
          deploydashboard "./create-$filename" "$AccountVariable" "$QSRegion" $dashboardID 
       fi            
  fi
done


