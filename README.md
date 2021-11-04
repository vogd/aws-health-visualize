# aws-health-visualize

Script consist of templates where variables replaced based on aws account, quicksight account region and user, etc
Datasource Template created for S3 data generated by automation from 
https://aws.amazon.com/blogs/mt/use-aws-lambda-and-amazon-quicksight-to-build-a-dashboard-for-aws-health-events-in-organizational-view/

Dataset generated to describe data structure
Dashboard deployed from temporary dashboard template shared in test aws acount

Prerequisistes:
- **Deploy Automation from CF template **https://aws-org-health-dashboard-2021.s3.ap-southeast-2.amazonaws.com/aws-health-cfn-stack.yaml
![image](https://user-images.githubusercontent.com/7371990/140425531-c1a0c134-9b78-4bf3-8d98-788ced3c0026.png)

![image](https://user-images.githubusercontent.com/7371990/140425592-101a2c0b-7607-4a1c-a3a6-9a5eeef26c75.png)

![image](https://user-images.githubusercontent.com/7371990/140425782-e81a8365-2339-4d13-b74f-4b5a02e4f995.png)

- **Proceed to next window with default settings. Mark following at the end.**
![image](https://user-images.githubusercontent.com/7371990/140425890-cee1e74f-fd93-48c4-97a4-299346341518.png)

![image](https://user-images.githubusercontent.com/7371990/140425932-81c3beb7-6d29-4d76-9b12-c012cc1795dc.png)

- **Waitfor main stack to complete.**
![image](https://user-images.githubusercontent.com/7371990/140426257-2434f38f-c390-499a-af32-2500aaa32c24.png)


- **Setup QuickSight Account as per blog instruction**
!!!!!Account should be setup in the same region where health visualization stack is deployed !!!!!

- **Allow Quicksight to access S3 bucket created by CF template from blog**
![image](https://user-images.githubusercontent.com/7371990/140425251-e4443c85-f292-4ed0-8ae1-cb3b7066362c.png)
Hit Save
![image](https://user-images.githubusercontent.com/7371990/140428132-39e85e67-a701-4078-a61f-ba8aae66c0ec.png)
S3 will appear in the list of allowed for IAM role
![image](https://user-images.githubusercontent.com/7371990/140428209-f0204d3c-9962-4781-a30f-985540aed500.png)

- **Check S3**
![image](https://user-images.githubusercontent.com/7371990/140425307-956a22e3-8d6c-434b-b592-1a7808ce1b51.png)

- **Select Bucket created by automation**
![image](https://user-images.githubusercontent.com/7371990/140425439-8d51678a-621b-4865-a86e-89868aa0654a.png)


Steps to complete:
1) Clone repo
git clone git@github.com:vogd/aws-health-visualize.git
Cloning into 'aws-health-visualize'...
remote: Enumerating objects: 24, done.
remote: Counting objects: 100% (24/24), done.
remote: Compressing objects: 100% (21/21), done.
remote: Total 24 (delta 6), reused 11 (delta 2), pack-reused 0
Receiving objects: 100% (24/24), 21.04 KiB | 694.00 KiB/s, done.
Resolving deltas: 100% (6/6), done.

2) Ensure S3 Bucket exist and or you are logged under correct account in your awscli
aws s3 ls
2021-10-18 16:31:52 cloudtrail-awslogs-453297385969-aaa6hupv-do-not-delete
2021-10-19 06:21:27 do-not-delete-audit-453297385969
2021-11-04 14:57:01 yourname-for-healthvisualization

3) Launch script 
./deployhealthvisuals.sh

If following error returned :
No accountid -a xxxx and bucketname -b yyyy  parameters set. Taking from environment

Reason:
Default region configured to us-east-1 nothing would be returned:
aws --profile learning3 cloudformation describe-stacks --query Stacks[].Parameters[*] --output text | grep "S3BucketNameforHealthData"

ENSURE default aws cli profile configured with the same region where stack were created.
Command to check profile:
bash-3.2$ cat ~/.aws/config
[default]
region = us-west-2
output = json

......

[profile learning3]
region = us-east-1
credential_process = xxxxx:yyyyyyy/user

$ aws --profile learning3 cloudformation describe-stacks --query Stacks[].Parameters[*] --region us-west-2 --output text | grep "S3BucketNameforHealthData"
S3BucketNameforHealthData	yourname-for-healthvisualization

Solution:
Change profile default region in .aws/config to execute the script in correct region.
Or
Can override account and bucket templates using -a and -b parameters
Originally automation will be looking for a bucket from Stack parameter **S3BucketNameforHealthData**
![image](https://user-images.githubusercontent.com/7371990/140426846-3c5e269a-03b0-4093-b939-1788c0e200e5.png)


4) Script will query aws cli env for aws account and get S3 bucket value from described stacksets.
5) If stack from blog article was not deployed previously - you can override the bucket name via -b option
6) Steps to complete once dashboard deployed to allow locat dashboard modification:

How to save a dashboard as an analysis?

Go to your Templated Dashboard.
Click “Share”
Click “Share dashboard”
Click “Manage dashboard access”
Check the Save as box for your user
Confirm
Close window
You should now see a “Save as”
Click "Save as"
Name your Analysis
Once completed, you can then customize the Analysis filters, visuals etc.


-Open Dashboard

![image](https://user-images.githubusercontent.com/7371990/140420492-ae674248-3515-4b62-8734-40fd15f3dae7.png)

-Select option "Share Dashboard" under top right pane Share

![image](https://user-images.githubusercontent.com/7371990/140420618-e63b454d-3ff0-47fc-8fa2-4d5ba095e59a.png)

-Select "Manage dashboard access"

![image](https://user-images.githubusercontent.com/7371990/140420668-571d7be0-db50-47ec-a970-7f1b73f67127.png)

-Allow "Save As" option

![image](https://user-images.githubusercontent.com/7371990/140420736-ee08a9ef-8b7c-4505-ae7d-5eed37ff2911.png)
![image](https://user-images.githubusercontent.com/7371990/140420781-15370b55-f9c7-446b-9eef-9640d0075311.png)

-Following option should appear

![image](https://user-images.githubusercontent.com/7371990/140420816-3c71c0fa-2a7b-408a-b645-b85995c0ad45.png)

-Refresh dashboard tab in browser

![image](https://user-images.githubusercontent.com/7371990/140420936-88e48a8f-8d41-4d80-a2d9-ceb82d51d60d.png)

-If not helped Close Quicksight window and reopen it in a new tab. 
Open dashboard again.Save As option should appear for the dashboard.

![image](https://user-images.githubusercontent.com/7371990/140421830-37cbd268-2119-49eb-940a-c11f7d038b10.png)

You are ready to make your changes !
