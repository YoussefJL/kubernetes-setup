# Provisioning tools for the cluster setup
# this script is to install AWSCLI, eksctl and kubectl
yum --help &>> /dev/null
if [ $? -eq 0 ]
then
  yum install zip unzip -y
else
  apt update && apt install zip unzip -y
fi
#installing AWSCLI version 2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

#downloading the binary of eksctl 
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp


sudo mv /tmp/eksctl /usr/local/bin
eksctl version

#Downloading kubectl
curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.17.9/2020-08-04/bin/linux/amd64/kubectl
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin
kubectl version --short --client

