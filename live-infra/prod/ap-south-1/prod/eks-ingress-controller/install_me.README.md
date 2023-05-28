```shell
kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master" && \
helm repo add eks https://aws.github.io/eks-charts && \
helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller \
--set clusterName=<cluster-name> \
--set serviceAccount.create=false \
--set serviceAccount.name=aws-load-balancer-controller \
-n kube-system

```

```shell
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=ondc-prod-prod-eks-cluster \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller 
```

```shell
eksctl utils associate-iam-oidc-provider \\n    --region ap-south-1 \\n    --cluster ondc-prod-prod-eks-cluster --approve
curl -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json
aws iam create-policy \\n    --policy-name AWSLoadBalancerControllerIAMPolicy \\n    --policy-document file://iam-policy.json
eksctl create iamserviceaccount \\n  --cluster=my-cluster \\n  --namespace=kube-system \\n  --name=aws-load-balancer-controller \\n  --role-name AmazonEKSLoadBalancerControllerRole \\n  --attach-policy-arn=arn:aws:iam::111122223333:policy/AWSLoadBalancerControllerIAMPolicy \
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm install aws-load-balancer-controller eks/aws-load-balancer-controller \\n  -n kube-system \\n  --set clusterName=ondc-prod-prod-eks-cluster \\n  --set serviceAccount.create=false \\n  --set serviceAccount.name=aws-load-balancer-controller
```






 