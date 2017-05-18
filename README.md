# Architecture POC for a distributed Inventory / Collector on ManageIQ

Prerequistes:

* Running minishift
* All will be done in the default project `myproject`

## Clone required repositories

```bash
git clone https://github.com/durandom/manageiq-dos
git clone https://github.com/durandom/manageiq-kafka-client
```

## Prepare minishift to run manageiq

```bash
# add required roles to openshift to make it available as a provider in manageiq
minishift addons install --force manageiq-dos/minishift/minishift-addons/manageiq-infra
minishift addons list
# - manageiq-infra : enabled    P(10)
minishift config set memory 8192
minishift config view
# - cpus                 : 4
# - memory               : 8192
# - show-libmachine-logs : true
minishift start

# let containers run privileged because the manageiq app container still requires that
oc login -u system:admin
oc adm policy add-scc-to-user privileged system:serviceaccount:myproject:default

minishift openshift config set --target master --patch '{"imagePolicyConfig": {"maxImagesBulkImportedPerRepository": 100}}'
# Patching OpenShift configuration /var/lib/origin/openshift.local.config/master/master-config.yaml with {"imagePolicyConfig": {"maxImagesBulkImportedPerRepository": 100}}
# Restarting OpenShift

# add manageiq app template
oc login -u developer -n myproject
oc create -f https://raw.githubusercontent.com/ManageIQ/manageiq-pods/master/templates/miq-template.yaml

# create manageiq app
oc new-app --template=manageiq -p APPLICATION_MEM_REQ=2Gi
```

## Setup Kafka

```bash
manageiq-kafka-client/kafka/up.sh
# + oc login -u developer -p developer -n myproject
# + oc create -f https://raw.githubusercontent.com/durandom/openshift-kafka/master/resources.yaml
# + oc rollout status -w dc/apache-kafka
# + oc expose dc apache-kafka --type=LoadBalancer --name=apache-kafka-ingress
# + oc export svc apache-kafka-ingress

# create inventory topic with 100 partitions and a short retention time
manageiq-kafka-client/kafka/create_topic.sh
# bin/kafka-topics.sh --create --zookeeper apache-kafka --replication-factor 1 --partitions 100 --topic inventory
```

## Setup redis service

```bash
manageiq-kafka-client/redis/up.sh
```

## Create Inventory service

```bash
# load template and deply inventory service
cd manageiq-kafka-client/inventory
oc create -f template.yml
oc new-app --template=manageiq-inventory

# build inventory container and publish it to openshift registry
eval $(minishift docker-env)
docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)
make build
make release

# get logs from service
oc get pods -l app=manageiq-inventory
oc logs manageiq-inventory-1-3bwdg
```

## Create Collector services

```bash
cd ../collector
oc create -f template.yml

# create one collector
oc new-app --template manageiq-collector -p NAME=ocp1

# build inventory container and publish it to openshift registry
make build
make release
```


