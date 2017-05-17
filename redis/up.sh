#!/usr/bin/env bash

oc login -u developer -p developer -n myproject
oc new-app https://raw.githubusercontent.com/openshift/origin/master/examples/db-templates/redis-ephemeral-template.json
oc rollout status -w dc/redis

oc expose dc redis --type=LoadBalancer --name=redis-ingress
oc export svc redis-ingress
