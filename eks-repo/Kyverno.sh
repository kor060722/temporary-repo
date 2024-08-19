apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: park:admin
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["update", "delete", "create"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: park:admin
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: park:admin
subjects:
- kind: User
  name: root-admin
  apiGroup: rbac.authorization.k8s.io

---

apiVersion: kyverno.io/v1
kind: ClusterPolicy

metadata:
  name: require-labels
  annotations:
    policies.kyverno.io/title: Add RoleBinding
    policies.kyverno.io/subject: RoleBinding

spec:
  background: false
  validationFailureAction: audit
  rules:
  - name: check-for-labels
    match:
      any:
      - resources:
          kinds:
          - "*"
    exclude:
      any:
      - clusterRoles:
        - root-admin
    validate:
      pattern:
        metadata:
          labels:
            protected: "true"
