#!/bin/bash
kubectl apply -f ./conf/heapster/rbac/heapster-rbac.yaml
kubectl apply -f ./conf/heapster/influxdb.yaml
kubectl apply -f ./conf/heapster/heapster.yaml
kubectl apply -f ./conf/heapster/grafana.yaml
