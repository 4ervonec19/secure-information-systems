## Политики безопасности и аудит в k8s


- `Цель работы:` Изучить механизмы безопасности Kubernetes на практике: от эскалации привилегий через сервис-аккаунты до внедрения политик валидации и мутации с помощью Kyverno, а также освоить инструменты аудита соответствия CIS Benchmark.

- `Требования:` Кластер Kubernetes (minikube, kind, или облачный), `kubectl, helm, kyverno, kube-bench, kubescape.`


## Подготовка среды

1. Выполним установку кластера через minikube и запустим через `minikube start:`

```bash
brew install minikube kubectl
minikube start
```

Вывод:

```bash
minikube start
😄  minikube v1.38.1 on Darwin 26.5 (arm64)
E0529 17:27:20.081556   64730 start.go:846] api.Load failed for minikube: filestore "minikube": Docker machine "minikube" does not exist. Use "docker-machine ls" to list machines. Use "docker-machine create" to add a new one.
✨  Using the docker driver based on existing profile
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.50 ...
💾  Downloading Kubernetes v1.35.1 preload ...
    > index.docker.io/kicbase/sta...:  483.40 MiB / 483.40 MiB  100.00% 2.10 Mi
    > preloaded-images-k8s-v18-v1...:  224.15 MiB / 243.95 MiB  91.88% 1005.94 ❗  minikube was unable to download gcr.io/k8s-minikube/kicbase:v0.0.50, but successfully downloaded docker.io/kicbase/stable:v0.0.50 as a fallback image
    > preloaded-images-k8s-v18-v1...:  243.95 MiB / 243.95 MiB  100.00% 954.33 
🔥  Creating docker container (CPUs=2, Memory=4000MB) ...
🐳  Preparing Kubernetes v1.35.1 on Docker 29.2.1 ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

2. Убедимся, что кластер доступен:

```bash
kubectl cluster-info
```

Вывод:

```bash
Kubernetes control plane is running at https://127.0.0.1:61345
CoreDNS is running at https://127.0.0.1:61345/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

3. Создаём два экспериментальных пространства имён `(namespase).`

```bash
kubectl create namespace target-ns
kubectl create namespace sensitive-ns
```

Вывод:

```bash
namespace/target-ns created
namespace/sensitive-ns created
```

4. Дополнительно:

```bash
docker ps -a | grep minikube
```

Вывод:
```bash
2562f021b3e0   kicbase/stable:v0.0.50      "/usr/local/bin/entr…"   11 minutes ago   Up 11 minutes              127.0.0.1:61344->22/tcp, 127.0.0.1:61346->2376/tcp, 127.0.0.1:61348->5000/tcp, 127.0.0.1:61345->8443/tcp, 127.0.0.1:61347->32443/tcp   minikube
```

Видим, несколько портов от контейнера Docker, в котором minikube запускает наш Kubernetes-кластер.

Можем посмотреть ноды:

```bash
kubectl get nodes -o wide
```

Вывод:

```bash
NAME       STATUS   ROLES           AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION     CONTAINER-RUNTIME
minikube   Ready    control-plane   16m   v1.35.1   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.12.54-linuxkit   docker://29.2.1
```

Посмотрим на пространства имён:

```bash
kubectl get namespaces
```

Вывод:

```bash
NAME              STATUS   AGE
default           Active   17m
kube-node-lease   Active   17m
kube-public       Active   17m
kube-system       Active   17m
sensitive-ns      Active   11m
target-ns         Active   11m
```

Можем посмотреть на поды

```bash
kubectl get pods -n kube-system
```

Вывод:

```bash
NAME                               READY   STATUS    RESTARTS      AGE
coredns-7d764666f9-lfwp9           1/1     Running   0             18m
etcd-minikube                      1/1     Running   0             18m
kube-apiserver-minikube            1/1     Running   0             18m
kube-controller-manager-minikube   1/1     Running   0             18m
kube-proxy-ts5wx                   1/1     Running   0             18m
kube-scheduler-minikube            1/1     Running   0             18m
storage-provisioner                1/1     Running   1 (18m ago)   18m
```

Видим, что в контейнере в рамках пространства `kube-system` запущены поды, соответствующие компонентам мастер-ноды `(apiserver, controller-manager, scheduler, etcd).` Видим также и поды `kube-proxy, core-dns.` Если зайдём внутрь контейнера, то обнаружим процесс `kubelet.`

Итого, получим, что в рамках одного контейнера запущена ОС Debian, в которой запущены процессы, соответствующие как сущностям мастер-ноды, так и воркер-ноды. Все они (кроме kubelet) тоже являются подами, работающими на этом же узле.

## Задание №1. Эскалация привелегий: перехват секретов через сервис-аккаунт

- `Цель:` Продемонстрировать риски, связанные с сервис-аккаунтами, имеющими избыточные права
`(cluster-admin)`, и показать, как злоумышленник может использовать их для доступа к секретам в
других пространствах имен.

1. Развернём приложение с широкими правами

```bash
brew install helm
helm install demo-attack ./application --namespace target-ns --create-namespace
```

Получим:

```bash
NAME: demo-attack
LAST DEPLOYED: Fri May 29 18:36:25 2026
NAMESPACE: target-ns
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
TEST SUITE: None
```

Убедимся, что под запущен:

```bash
kubectl get pods -n target-ns
```

Вывод:

```bash
NAME                                       READY   STATUS    RESTARTS   AGE
demo-attack-my-demo-app-579c8b767d-pxckx   0/1     Pending   0          5m45s
demo-attack-my-demo-app-579c8b767d-t6q4j   1/1     Running   0          5m45s
```

Далее:

```bash
kubectl describe pod -n target-ns demo-attack-my-demo-app-579c8b767d-t6q4j | grep "Service Account"
```

Получаем:

```bash
Service Account:  demo-risky-sa
```

Полагаю, это то, что и имеется в виду. Мы можем посмотреть привязку ролей для данного сервисного аккаунта:

```bash
kubectl get rolebinding,clusterrolebinding -n target-ns -o wide | grep demo-risky-sa
```

Вывод:

```bash
clusterrolebinding.rbac.authorization.k8s.io/demo-risky-sa-cluster-admin
ClusterRole/cluster-admin 16m   
target-ns/demo-risky-sa   16m
```

Видим, что для данного неймспейса объект `ClusterRoleBinding` связывает сервисный аккаунт `demo-risky-sa` с кластерной ролью `cluster-admin.` Получается, при каждом запросе API-сервер по RBAC будет видеть, что данной поде доступно все (широкие права).

2. Создадим тестовый секрет в другом пространстве имён `sensitive-ns,` который будет целью атаки:

```bash
kubectl create secret generic password --from-literal=password=password123 -n sensitive-ns

kubectl create secret generic db-password --from-literal=db-password=password_database_123 -n sensitive-ns

kubectl create secret generic db-credentials --from-literal=db-credentials=login:login_password:password -n sensitive-ns
```

Вывод:

```bash
secret/password created
secret/db-password created
secret/db-credentials created
```

Проверяем:

```bash
kubectl get secrets -n sensitive-ns
```

Вывод:

```bash
NAME             TYPE     DATA   AGE
db-credentials   Opaque   1      10s
db-password      Opaque   1      15m
password         Opaque   1      15m
```

Секреты для `sensitive-ns` созданы.

3. Проведём атаку, получим секреты из `namespace` с широкими правами:

- Имя работающего пода:

```bash
kubectl get pods -n target-ns
# demo-attack-my-demo-app-579c8b767d-t6q4j (Running)
```

- Внутри контейнера:

```bash
kubectl exec -it demo-attack-my-demo-app-579c8b767d-t6q4j -n target-ns -- sh
```

- Получаем IP для API-сервера:

```bash
kubectl get svc kubernetes -n default
# 10.96.0.1 (было curl: (6) Could not resolve host: kubernetes.default.svc (Domain name not found))
```

- Делаем `curl` для получения секретов:

```bash
curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
  https://10.96.0.1/api/v1/namespaces/sensitive-ns/secrets
```

`-k`, чтобы не проверять `TLS-соединение`, иначе вылетит ошибка.

Получаем ответ:

```bash
"data": {
    "db-credentials": "bG9naW46bG9naW5fcGFzc3dvcmQ6cGFzc3dvcmQ="
}
...
"data": {
    "db-password": "cGFzc3dvcmRfZGF0YWJhc2VfMTIz"
}
...
"data": {
    "password": "cGFzc3dvcmQxMjM="
}
```

Все секреты получены.

4. Удаление 

```bash
helm uninstall demo-attack -n target-ns
# release "demo-attack" uninstalled
```

```bash
kubectl delete secret db-credentials -n sensitive-ns
kubectl delete secret password -n sensitive-ns
kubectl delete secret db-password -n sensitive-ns
# secret "db-credentials" deleted from sensitive-ns namespace
# ...
# ...
```

## Задание 2. Валидирующие политики Kyverno: запрет на Pod Security

- `Цель:` Установить Kyverno и создать политику валидации, которая запрещает использование
привилегированных контейнеров, с применением условия на определенный ресурс.

1. Установка `kyverno`

```bash
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update
helm install kyverno kyverno/kyverno --namespace kyverno --create-namespace
```

Вывод:

```bash
"kyverno" has been added to your repositories
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "kyverno" chart repository
Update Complete. ⎈Happy Helming!⎈
NAME: kyverno
LAST DEPLOYED: Sat May 30 13:58:08 2026
NAMESPACE: kyverno
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
NOTES:
Chart version: 3.8.1
Kyverno version: v1.18.1

Thank you for installing kyverno! Your release is named kyverno.

The following components have been installed in your cluster:
- CRDs
- Admission controller
- Reports controller
- Cleanup controller
- Background controller


⚠️  WARNING: Setting the admission controller replica count below 2 means Kyverno is not running in high availability mode.


⚠️  WARNING: PolicyExceptions are disabled by default. To enable them, set '--enablePolicyException' to true.

💡 Note: There is a trade-off when deciding which approach to take regarding Namespace exclusions. Please see the documentation at https://kyverno.io/docs/installation/#security-vs-operability to understand the risks.
```

Выполним проверку:

```bash
kubectl get pods -n kyverno
```

Вывод:

```bash
NAME                                             READY   STATUS    RESTARTS   AGE
kyverno-admission-controller-66756fbfdf-xnt4g    1/1     Running   0          2m38s
kyverno-background-controller-57f7cb7c48-bs9lr   1/1     Running   0          2m38s
kyverno-cleanup-controller-75c566db9c-5gcnz      1/1     Running   0          2m38s
kyverno-reports-controller-dfdd969cd-hmsqv       1/1     Running   0          2m38s
```

`Kyverno` установлен.

2. Выполним команду `kubectl describe pod demo-attack-my-demo-app-579c8b767d-wmdnq -n target-ns` и получим в выводе:

```bash
Volumes:
  host-root:
    Type:          HostPath (bare host directory volume)
    Path:          /
    HostPathType:  Directory
```

Видим, что корень файловой системы хоста явно проброшен в контейнер. Это наиболее серьёзная уязвимость, поэтому нужно создать соответствующую `Validation Policy.` Найдём её в доке Kyverno: https://kyverno.io/policies/pod-security/baseline/disallow-host-path/disallow-host-path/

В строке `[23]` добавляем `pre-condition (по имени пода).`

Далее, применяем политику к кластеру:

```bash
kubectl apply -f disallow-host-path-volume-policy.yaml
```

Вывод:

```bash
clusterpolicy.kyverno.io/disallow-host-path-volume-policy created
```

Наконец, демонстрируем ошибку:

```bash
helm uninstall demo-attack -n target-ns
helm install demo-attack ./application --namespace target-ns --create-namespace
kubectl get pods -n target-ns
kubectl logs -n kyverno deployment/kyverno-admission-controller --tail=20
```

Получаем вывод: `No resources found in target-ns namespace.`

Ресурсы не создались.

Можно посмотреть в логи Kyverno:

```bash
kubectl logs -n kyverno deployment/kyverno-admission-controller --tail=1
```

Вывод:

```bash
2026-05-30T11:39:28Z TRC github.com/kyverno/kyverno/pkg/webhooks/utils/block.go:29 > blocking admission request URLParams= action=validate clusterroles=["system:basic-user","system:controller:replicaset-controller","system:discovery","system:public-info-viewer","system:service-account-issuer-discovery"] gvk="/v1, Kind=Pod" gvr="/v1, Resource=pods" kind=Pod logger=webhooks/resource/validate name=demo-attack-my-demo-app-579c8b767d-rrcps namespace=target-ns operation=CREATE policy=disallow-host-path resource=target-ns/Pod/demo-attack-my-demo-app-579c8b767d-rrcps resource.gvk="/v1, Kind=Pod" roles=[] uid=a3f8b54e-0e47-4721-89c6-7ba200f1ed51 user={"extra":{"authentication.kubernetes.io/credential-id":["JTI=5ea9722b-ba18-405a-b3db-ba5ff8b9c39c"]},"groups":["system:serviceaccounts","system:serviceaccounts:kube-system","system:authenticated"],"uid":"d578d4e6-f75a-400c-8dbc-5d41084bf28e","username":"system:serviceaccount:kube-system:replicaset-controller"} v=2
```

Видим строчку `blocking admission request,` что говорит о том, что Kyverno блокирует создание пода с монтированием хостовой директории ноды.

## Задание 3. Мутирующие политики Kyverno: мутирование секретов

- `Цель:` Создать мутирующую политику, которая убирает у роли возможность читать секрет. По примеру политик и версии киверно аналогично пункту выше.

Создаём `mutate-remove-secret-role.yaml` и добавляем:

```bash
kubectl apply -f mutate-remove-secret-role.yaml
# mutatingpolicy.policies.kyverno.io/remove-secret-read-role created
```

Создаём тестовую роль с доступом к секретами `test-role-secrets.yaml:`
 ```bash
kubectl apply -f test-role-secrets.yaml
# role.rbac.authorization.k8s.io/test-secret-role created
```

Можем посмотреть на то, как тестовая роль была мутирована:
```bash
kubectl get role test-secret-role -n target-ns -o yaml
```

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"rbac.authorization.k8s.io/v1","kind":"Role","metadata":{"annotations":{},"name":"test-secret-role","namespace":"target-ns"},"rules":[{"apiGroups":[""],"resources":["pods","secrets"],"verbs":["get","list"]},{"apiGroups":[""],"resources":["configmaps"],"verbs":["get"]}]}
  creationTimestamp: "2026-05-30T13:38:13Z"
  name: test-secret-role
  namespace: target-ns
  resourceVersion: "41642"
  uid: 1cf2eb00-d734-4ff5-af1d-558cb387e9e3
rules:
- apiGroups:
  - ""
  resources:
  - configmaps
  verbs:
  - get
```

Видим, что для ресурсов `secrets` отсутствуют `get` и `list.` Роль поменялась за счёт `Kyverno.`

Далее создадим новый сервисный аккаунт:

```bash
kubectl create serviceaccount test-sa -n target-ns
# serviceaccount/test-sa created
```

Привязываем к нему мутированную роль:

```bash
kubectl create rolebinding test-sa-binding \
  --role=test-secret-role \
  --serviceaccount=target-ns:test-sa \
  -n target-ns

# rolebinding.rbac.authorization.k8s.io/test-sa-binding created
```

Создаём под с данным `ServiceAccount:`

```bash
kubectl apply -f test-pod-mutaded.yaml -n target-ns
# pod/test-pod-mutated created

kubectl get pods -n target-ns
```

Вывод:

```bash
NAME                                       READY   STATUS    RESTARTS   AGE
demo-attack-my-demo-app-579c8b767d-8z86d   1/1     Running   0          12m
demo-attack-my-demo-app-579c8b767d-zp82s   0/1     Pending   0          12m
test-pod-mutated                           1/1     Running   0          49s
```

Заходим внутрь:

```bash
kubectl exec -it test-pod-mutated -n target-ns -- sh
```

И шлём оттуда `curl:`

```bash
curl -k -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" \
    https://10.96.0.1/api/v1/namespaces/sensitive-ns/secrets
```

Получаем ответ:

```json
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "secrets is forbidden: User \"system:serviceaccount:target-ns:test-sa\" cannot list resource \"secrets\" in API group \"\" in the namespace \"sensitive-ns\"",
  "reason": "Forbidden",
  "details": {
    "kind": "secrets"
  },
  "code": 403
}
```

Всё сработало корректно! Сервисный аккаунт с такой ролью действительно не может читать секреты.

##


