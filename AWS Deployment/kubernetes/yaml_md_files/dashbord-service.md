    # Ignore this line 
    # Please edit the object below. Lines beginning with a '#' will be ignored,
    # and an empty file will abort the edit. If an error occurs while saving this file will be
    # reopened with the relevant failures.
    #
    apiVersion: v1
    kind: Service
    metadata:
      annotations:
        kubectl.kubernetes.io/last-applied-configuration: |
          {"apiVersion":"v1","kind":"Service","metadata":{"annotations":{},"labels":{"k8s-app":"kubernetes-dashboard"},"name":"kubernetes-dashboard","namespace":"kubernetes-dashboard"},"spec":{"ports":[{"port":443,"targetPort":8443}],"selector":{"k8s-app":"kubernetes-dashboard"}}}
      creationTimestamp: "2024-07-06T11:14:04Z"
      labels:
        k8s-app: kubernetes-dashboard
      name: kubernetes-dashboard
      namespace: kubernetes-dashboard
      resourceVersion: "1668"
      uid: e4211a82-97a1-4a65-b52e-be3bcb3b5150
    spec:
      clusterIP: 10.96.128.226
      clusterIPs:
      - 10.96.128.226
      externalTrafficPolicy: Cluster
      internalTrafficPolicy: Cluster
      ipFamilies:
      - IPv4
      ipFamilyPolicy: SingleStack
      ports:
      - nodePort: 31000
        port: 443
        protocol: TCP
        targetPort: 8443
      selector:
        k8s-app: kubernetes-dashboard
      sessionAffinity: None
      type: NodePort
    status:
      loadBalancer: {}