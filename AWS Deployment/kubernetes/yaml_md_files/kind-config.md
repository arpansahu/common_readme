    # Ignore this line 
    kind: Cluster
    apiVersion: kind.x-k8s.io/v1alpha4
    nodes:
    - role: control-plane
      extraPortMappings:
      - containerPort: 80
        hostPort: 7800
      - containerPort: 443
        hostPort: 7801
      extraMounts:
      - hostPath: /etc/kubernetes/kubelet-config.yaml
        containerPath: /var/lib/kubelet/config.yaml