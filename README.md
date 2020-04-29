# AI workloads in the IBM Cloud

This project provides the files and information for using various IBM Cloud services to automate the creation
of a VPC and a Power GPU virtual machine. A PowerAI sample tensorflow python script is then run and the output
is written to an IBM Cloud Object Storage bucket. This is all driven by an IBM Cloud function triggered by a
timer. A second trigger will be invoked when the ICOS bucket is written to and will destroy the environment. 

![Architecture](https://github.com/darrellschrag/powerai-vpc-schematics/blob/master/images/diagram.png)

