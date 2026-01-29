eksctl create iamidentitymapping \
    --cluster ondc-prod-prod-eks-reference-apps-cluster  \
    --region ap-south-1 \
    --arn arn:aws:iam::568130295144:user/ecr-pusher \
    --username admin-user \
    --group system:masters