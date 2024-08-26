
# Docker Space Management Process

## 0. Check System Size

First, check the current system disk usage:

```bash
df -h
```

## 1. Check Docker Space Usage

Use the following command to check which elements are occupying the most space in Docker:

```bash
docker system df -v
```

### Output Example:

#### Images space usage:
```plaintext
REPOSITORY                                     TAG       IMAGE ID       CREATED        SIZE      SHARED SIZE   UNIQUE SIZE   CONTAINERS
harbor.arpansahu.me/library/clock_work         20        ddac0513558f   24 hours ago   1.16GB    921.2MB       234.6MB       1
harbor.arpansahu.me/library/django_starter     latest    cc89dbd0952e   3 days ago     1.21GB    921.2MB       291.8MB       1
harbor.arpansahu.me/library/school_chale_hum   latest    1e24178fea65   7 days ago     1.23GB    921.2MB       306.2MB       1
<none>                                         <none>    7bf8eb7abfa4   7 days ago     263MB     0B            263.3MB       1
rancher/rancher                                latest    91a26da6b860   2 months ago   2.05GB    0B            2.045GB       1
...
```

#### Containers space usage:
```plaintext
CONTAINER ID   IMAGE                                                 COMMAND                  LOCAL VOLUMES   SIZE      CREATED        STATUS                       NAMES
32ff271a9782   harbor.arpansahu.me/library/clock_work:20             "supervisord -c /etc…"   0               457kB     16 hours ago   Up About an hour             clock_work
...
```

#### Local Volumes space usage:
```plaintext
VOLUME NAME                                                        LINKS     SIZE
c343410149239b5d0a656c6a70ec87d7b26d71d988300fc6d92f15f70aaa4e07   1         36.79GB
...
```

#### Build cache usage:
```plaintext
CACHE ID   CACHE TYPE   SIZE      CREATED   LAST USED   USAGE     SHARED
```

## 2. Identify the Largest Volume

Based on the previous output, identify the largest volume, which is likely associated with a kind cluster. Use the following command to find the Docker container using that volume:

```bash
docker ps -a --filter "volume=c343410149239b5d0a656c6a70ec87d7b26d71d988300fc6d92f15f70aaa4e07" --format "table {{.ID}}	{{.Names}}"
```

### Output Example:
```plaintext
CONTAINER ID   NAMES
20b079457e00   kind-control-plane
```

## 3. Access the Docker Container

Access the identified Docker container:

```bash
docker exec -it kind-control-plane sh
```

## 4. Navigate to the Snapshots Directory

Navigate to the snapshots directory inside the container:

```bash
cd /var/lib/containerd/io.containerd.snapshotter.v1.overlayfs/snapshots/
```

## 5. Remove Unused Images

To free up space, remove unused images:

```bash
crictl rmi --prune
```

## 6. Remove All Snapshots

To clear all snapshots and further free up space, run:

```bash
rm -rf *
```

Exit the container:

```bash
exit
```

## 7. Recheck System Size

Finally, recheck the system disk usage to verify the changes:

```bash
df -h
```
