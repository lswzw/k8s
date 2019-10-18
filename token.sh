kubectl create serviceaccount dashboard-admin -n kube-system &>/dev/null

kubectl create clusterrolebinding dashboard-admin --clusterrole=cluster-admin --serviceaccount=kube-system:dashboard-admin &>/dev/null

kubectl describe secrets -n kube-system $(kubectl -n kube-system get secret | awk '/dashboard-admin/{print $1}') | awk 'NR==13 {print}' | awk '{print $2}'
