1. Create Harbor Secret

kubectl create secret docker-registry harbor-registry-secret \
  --docker-server=harbor.arpansahu.me \
  --docker-username=admin \
  --docker-password=harborKesar302@ \
  --docker-email=admin@arpansahu.me