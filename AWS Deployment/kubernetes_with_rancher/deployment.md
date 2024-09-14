### Deployment

1. Create Harbor Secret

```yaml
kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=harbor.arpansahu.me \
  --docker-username=HARBOR_USERNAME \
  --docker-password=HARBOR_PASSWORD \
  --docker-email=YOUR_EMAIL_ID
```

2. Create deployment.yaml file and fill it with the below contents.

```yaml
  [DEPLOYMENT YAML]
```

3. Create a service.yaml file and fill it with the below contents.

```yaml
  [SERVICE YAML]
```

4. Create Env Secret for the project

```
  kubectl create secret generic <SECRET_NAME> --from-env-file=/root/projectenvs/<PROJECT_NAME>/.env
```