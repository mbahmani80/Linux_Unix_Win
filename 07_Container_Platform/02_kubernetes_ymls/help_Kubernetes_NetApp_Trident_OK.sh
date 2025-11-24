helm repo add netapp-trident https://netapp.github.io/trident-helm-chart

helm install trident netapp-trident/trident-operator --version 23.07.1  --create-namespace --namespace trident --set tridentDebug=true --set imageRegistry=quay.io/trident-mirror/full

helm status trident -n trident

helm get all trident -n trident

kubectl get all -n trident

kubectl get pod -o wide -n trident

cat 01_backend-tbc-ontap-nas-advanced.yaml

kubectl apply -f backend-tbc-ontap-nas-advanced.yaml  -n trident

kubectl get pod -n trident

kubectl get tbe,tbc -n trident

cat 02_Add_your_first_storage_class.yml

kubectl apply -f 02_Add_your_first_storage_class.yml -n trident
kubectl get sc
kubectl get storageclass

cat storage-class-ontapnas-gold.yaml

kubectl apply -f storage-class-ontapnas-gold.yaml

kubectl get storageclass

cat 03_Create_a_PersistentVolumeClaim_gold.yaml

kubectl create namespace ns-webserver

k apply -f 03_Create_a_PersistentVolumeClaim_gold.yaml -n ns-webserver

k get pvc -n ns-webserver

kubectl describe pvc task-pv-claim-gold -n ns-webserver

k apply -f 04_Create_a_PersistentVolumeClaim.yaml -n ns-webserver

cat 05_create_an_Ununtu_Pod_that_uses_your_PersistentVolumeClaim.yaml

k apply -f 05_create_an_Ununtu_Pod_that_uses_your_PersistentVolumeClaim.yaml -n ns-webserver
kubectl get pod --watch
kubectl get pod  -n ns-webserver

kubectl -n ns-webserver exec -it task-pv-pod-ubuntu -- /bin/bash

df -TH

ls /mnt

mkdir /mnt/test

ls /mnt/

k apply -f 06_create_an_Ngnix_Pod_that_uses_a_PersistentVolumeClaim.yaml -n ns-webserver

kubectl -n ns-webserver exec -it task-pv-pod-nginx -- /bin/bash

df -TH

sh -c "echo 'Hello from Kubernetes storage' > /usr/share/nginx/html/index.html"

cat /usr/share/nginx/html/index.html

apt update

apt install curl

curl http://localhost/





Delete

kube@k8s-cl04-master-0:~/my_kubernetes_ymls$ kubectl get tbe,tbc -n trident
NAME                                         BACKEND     BACKEND UUID
tridentbackend.trident.netapp.io/tbe-wqc9b   ontap-nas   4870aec4-b31a-4fe2-b055-8017cacabdf7

kube@k8s-cl04-master-0:~/my_kubernetes_ymls$ kubectl delete  tridentbackend.trident.netapp.io/tbe-wqc9b -n trident
tridentbackend.trident.netapp.io "tbe-wqc9b" deleted



kubectl get all,cm,secret,ing -A



Uninstall by using Helm

If you installed Astra Trident by using Helm, you can uninstall it by using helm uninstall.

#List the Helm release corresponding to the Astra Trident install.
$ helm ls -n trident
NAME          NAMESPACE       REVISION        UPDATED                                 STATUS          CHART                           APP VERSION
trident       trident         1               2021-04-20 00:26:42.417764794 +0000 UTC deployed        trident-operator-21.07.1        21.07.1

#Uninstall Helm release to remove Trident
$ helm uninstall trident -n trident
release "trident" uninstalled

k delete namespaces trident


https://www.kubesphere.io/blogs/restart-k8s-cluster/
https://www.kubesphere.io/docs/v3.3/cluster-administration/shut-down-and-restart-cluster-gracefully/
nodes=$(kubectl get nodes -o name)
for node in ${nodes[@]}
do
    echo "==== Shut down $node ===="
    ssh $node sudo shutdown -h 1
done

Terminating
NS=`kubectl get ns |grep Terminating | awk 'NR==1 {print $1}'` && kubectl get namespace "$NS" -o json   | tr -d "\n" | sed "s/\"finalizers\": \[[^]]\+\]/\"finalizers\": []/"   | kubectl replace --raw /api/v1/namespaces/$NS/finalize -f -


