# login to internal registry

eval $(minishift docker-env)
docker login -u developer -p $(oc whoami -t) $(minishift openshift registry)

# decoding secrets
❯ oc get secret manageiq-secrets -o yaml
apiVersion: v1
data:
  pg-password: Z3VYTExDQTU=
kind: Secret
metadata:
  creationTimestamp: 2017-05-17T07:47:48Z
  labels:
    app: manageiq-inventory
    template: manageiq-inventory
  name: manageiq-secrets
  namespace: myproject
  resourceVersion: "26187"
  selfLink: /api/v1/namespaces/myproject/secrets/manageiq-secrets
  uid: 1f2ec81d-3ad5-11e7-83f7-16565ae948db
type: Opaque

~/src/manageiq-dos/minishift master*
❯ echo Z3VYTExDQTU= | base64 --decode
guXLLCA5
