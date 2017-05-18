#!/usr/bin/env bash

KAFKA_POD=$(oc get pods -l app=apache-kafka -o jsonpath={.items..metadata.name})
echo $KAFKA_POD

# create a topic
oc rsh $KAFKA_POD bin/kafka-topics.sh --create --zookeeper apache-kafka --replication-factor 1 --partitions 100 --topic inventory

