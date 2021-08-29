#!/bin/bash

var7=$(ec2metadata --instance-id)

aws autoscaling set-instance-protection --instance-ids $var7 --auto-scaling-group-name video-conversion-w-git --protected-from-scale-in

main_obj=$(aws sqs receive-message --queue-url https://sqs.ap-south-1.amazonaws.com/968225076544/video-streaming --attribute-names All --message-attribute-names All --max-number-of-messages 1)

echo -e $main_obj > version.json

var1=$(jq '.Messages[] | {Body} | .Body | fromjson | . | .Records[] | {s3} | .s3 | .bucket | .name'  version.json) 

var2=$(jq '.Messages[] | {Body} | .Body | fromjson | . | .Records[] | {s3} | .s3 | .object | .key'  version.json)

var3=$(echo s3://$var1/$var2 | tr -d '""')

var4=$(echo $var2 | tr -d '""')

var5=$(echo $var4-1080.mp4)

var6=$(echo $var4-720.mp4)

aws s3 cp $var3 $var4

ffmpeg -i $var4 -filter:v "scale=w=1920:h=-1" -b:v 8M $var5

ffmpeg -i $var4 -filter:v "scale=w=1280:h=-1" -b:v 5M $var6

aws s3 cp $var5 s3://video-streaming-output-bucket

aws s3 cp $var6 s3://video-streaming-output-bucket

var8=$(jq '.Messages[] | {ReceiptHandle} | .ReceiptHandle'  version.json)

receipt_handle=$(echo $var8 | tr -d '""')

aws sqs delete-message --queue-url https://sqs.ap-south-1.amazonaws.com/968225076544/video-streaming --receipt-handle $receipt_handle

aws autoscaling set-instance-protection --instance-ids $var7 --auto-scaling-group-name video-conversion-w-git --no-protected-from-scale-in



 
