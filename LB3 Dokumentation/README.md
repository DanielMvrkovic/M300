# LB3 - Kubernetes extra Konfigurationen
## **Inhaltsverzeichnis**

- [LB3 - Kubernetes extra Konfigurationen](#lb3---kubernetes-extra-konfigurationen)
  - [**Inhaltsverzeichnis**](#inhaltsverzeichnis)
  - [**Kubeadm init error fix**](#kubeadm-init-error-fix)
  - [**LoadBalancer(bzw. Metallb)**](#loadbalancerbzw-metallb)
    - [**Installation**](#installation)
    - [**Konfiguration**](#konfiguration)
    - [**Services auf LoadBalancer umstellen**](#services-auf-loadbalancer-umstellen)
    - [**Zusatz**](#zusatz)
  - [**Weave Scope dashboard**](#weave-scope-dashboard)

<br>
<br>
<br>
<br>
<br>

## **Kubeadm init error fix**
Beim Initialisieren des Kubernetes Cluster kommt es zur folgender meldung

```
# kubeadm init
...
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
	[ERROR CRI]: container runtime is not running: output: time="2020-09-24T11:49:16Z" level=fatal msg="getting status of runtime failed: rpc error: code = Unimplemented desc = unknown service runtime.v1alpha2.RuntimeService"
, error: exit status 1
```

Grund für diesen error ist ein config-file unter "/etc/containerd/config.toml". Dieses file enthält es eine Zeile mit folgendem inhalt.
```toml
disabled_plugins = ["cri"]
```
Dieses File wird beim installieren von containerd automatisch erstellt und macht nur probleme. 

Eine Lösung wäre das File zu löschen und containerd neustarten.
```
# rm /etc/containerd/config.yaml
# systemctl restart containerd
# kubeadm init
```
<br>
<br>
<br>
<br>
<br>

## **LoadBalancer(bzw. Metallb)**
### **Installation**
Ordner für den LoadBalancer erstellen.
```
# mkdir $HOME/LoadBalancer
# cd $HOME/LoadBalancer
```
Einen Namespaces erstellen und das yaml von github herunterladen.
```
# kubectl create namespace metallb
# wget https://raw.githubusercontent.com/metallb/metallb/v0.12.1/manifests/metallb.yaml
```
Zuletzt einen Pod für Metallb kreieren.
```
# kubectl apply -f metallb.yaml
```

<br>
<br>

### **Konfiguration**
Normalweise würde man eine BGP Konfiguration machen, da aber der Kubernetes Cluster nur lokal ist und es keinen Router gibt, wird deshalb die Layer 2 Konfiguration genutzt.

Layer 2 ist die simpleste Konfiguration, es werden nur IPs benötigt. Die IPs müssen auch nicht auf network-interfaces der Nodes gebunden sein.

Die Konfiguration geht wie voll folgt:
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - [addresspool/range] [z.B 192.168.11.20-192.168.11.30]
```
diese Konfiguration kann in einem yaml-file geschrieben werden und dann übernohmen werden.
```
# kubectl apply -f metallb-configmap.yaml
```

<br>
<br>

### **Services auf LoadBalancer umstellen**
Um den LoadBalancer zu testen werde ich mit ihm, IPs an die nginx webserver verteilen. Um das hinzukriegen muss noch folgende zeile im nginx-silver.yaml file hinzugefügt werden.
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-nfs-silver-service
spec:
  selector:
    app: nginx-silver
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80

```
```
apiVersion: v1
kind: Service
metadata:
  name: nginx-nfs-silver-service
spec:
  selector:
    app: nginx-silver
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
```
Achtung, yaml ist wenn es um einrücken geht sehr pingelig, am besten genau so übernehmen wie in der Box oben.

Jetzt kann man nochmals "kubectl apply" machen und dann sollte der service automatisch eine IP aus der definierten Range bekommen.
```
#kubectl apply -f $HOME/deployment/nginx-silver.yaml
#kubectl get services
NAME                       TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE
kubernetes                 ClusterIP      10.96.0.1        <none>          443/TCP          24h
mysql                      ClusterIP      None             <none>          3306/TCP         9h
mysql-service              NodePort       10.96.173.26     <none>          3306:30914/TCP   9h
nginx-nfs-gold-service     LoadBalancer   10.109.91.165    192.168.11.22   80:31168/TCP     9h
nginx-nfs-platin-service   LoadBalancer   10.106.181.83    192.168.11.20   80:32159/TCP     9h
nginx-nfs-silver-service   LoadBalancer   10.101.180.240   192.168.11.21   80:30765/TCP     6h53m
```
Wie mann beim TYPE und EXTERNAL-IP sieht funktioniert er einwandfrei.

<br>
<br>
<br>

### **Zusatz**

Zusätzlich habe ich noch die nginx services, jetzt wo sie auch externe-IPs haben, im "/etc/hosts" mit zusätzlichem hsotname eingetragen. Das sieht wie folgt aus:
```
192.168.11.20 nfs-platin.k8s
192.168.11.21 nfs-silver.k8s
192.168.11.22 nfs-gold.k8s
```

<br>
<br>
<br>
<br>
<br>

## **Weave Scope dashboard**
Weave Scope erlaubt es prozesse, pods, container, hosts und vieles mehr grafische auf einem Dashboard abzubilden. Das Dashboard über einen Webbrowser wie Chrome aufrufbar und ist einfach zum Installieren.

Um Weave Scope zu installieren muss dieser befehl ausgeführt werden.
```
kubectl apply -f "https://cloud.weave.works/k8s/scope.yaml?k8s-version=$(kubectl version | base64 | tr -d '\n')"
```
Damit mit der erreichbar ist, benutzen wir die öffentliche IP des Master-Node. Das geht indem man einen NodePort öffnet. 
```
 # kubectl expose deployment Weave-Scope-app --type=NodePort --name=Weave-Scope-dashboard -n weave
```
Wenn man jetzt die services auflistet sollte man dort einen NodePort sehen, dort findet man dann auch den Port.
```
weave                  weave-dashboard             NodePort       10.100.188.72    <none>          4040:30651/TCP     
weave                  weave-scope-app             ClusterIP      10.106.214.187   <none>          80/TCP        
```
Damit ist das Dashboard erreichbar, hier noch ein paar snippets.

![Bild](https://raw.githubusercontent.com/DanielMvrkovic/M300-Service/main/LB3%20Dokumentation/Screenshot_1.png)

![Bild](https://raw.githubusercontent.com/DanielMvrkovic/M300-Service/main/LB3%20Dokumentation/Screenshot_2.png)

![Bild](https://raw.githubusercontent.com/DanielMvrkovic/M300-Service/main/LB3%20Dokumentation/Screenshot_3.png)

![Bild](https://raw.githubusercontent.com/DanielMvrkovic/M300-Service/main/LB3%20Dokumentation/Weave-scoper.png)
