# Procédure : Déploiement de kube-image-bouncer sur un cluster kubeadm

---

## **1. Préparation des certificats TLS**

Générez un certificat auto-signé et une clé pour le serveur webhook et pour le client API server. Le nom du certificat doit correspondre au nom du service Kubernetes (ex: `image-bouncer-webhook.default.svc`) :

```bash
# Générer le certificat et la clé pour le serveur webhook
openssl req -nodes -new -x509 -keyout webhook-key.pem -out webhook.pem -subj "/CN=image-bouncer-webhook.default.svc"

# Générer le certificat et la clé pour le client API server
openssl req -nodes -new -x509 -keyout apiserver-client-key.pem -out apiserver-client.pem
```

---

## **2. Créer un Secret Kubernetes pour les certificats**

Stockez les certificats dans un **Secret Kubernetes** de type `tls`. Les clés dans le Secret doivent correspondre aux noms attendus par le conteneur (`tls.key` et `tls.crt`) :

```bash
kubectl create secret tls tls-image-bouncer-webhook \
  --key webhook-key.pem \
  --cert webhook.pem
```

---

## **3. Déployer kube-image-bouncer en tant que Deployment**

Créez un fichier YAML pour le **Deployment** et le **Service** du webhook. Le volume monté depuis le Secret utilise les clés `tls.key` et `tls.crt` :

### **Fichier : `image-bouncer-deployment.yaml**`

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: image-bouncer-webhook
  namespace: default
spec:
  replicas: 2  # Pour la haute disponibilité
  selector:
    matchLabels:
      app: image-bouncer-webhook
  template:
    metadata:
      labels:
        app: image-bouncer-webhook
    spec:
      containers:
      - name: image-bouncer-webhook
        image: flavio/kube-image-bouncer
        args: ["-k", "/certs/tls.key", "-c", "/certs/tls.crt"]
        ports:
        - containerPort: 1323
        volumeMounts:
        - name: certs
          mountPath: /certs
          readOnly: true
      volumes:
      - name: certs
        secret:
          secretName: tls-image-bouncer-webhook
---
apiVersion: v1
kind: Service
metadata:
  name: image-bouncer-webhook
  namespace: default
spec:
  ports:
  - port: 443
    targetPort: 1323
  selector:
    app: image-bouncer-webhook
```

### **Appliquer le Deployment et le Service**

```bash
kubectl apply -f image-bouncer-deployment.yaml
```

---

## **4. Configurer le contrôleur d'admission ImagePolicyWebhook**

### **Option 1 : Fichier de configuration au format JSON (classique)**

Créez le fichier `/etc/kubernetes/admission_configuration.json` :

```json
{
  "imagePolicy": {
    "kubeConfigFile": "/etc/kubernetes/kube-image-bouncer.yml",
    "allowTTL": 50,
    "denyTTL": 50,
    "retryBackoff": 500,
    "defaultAllow": false
  }
}
```

### **Option 2 : Fichier de configuration au format YAML (recommandé pour Kubernetes ≥ 1.19)**

Créez le fichier `/etc/kubernetes/admission_configuration.yaml` :

```yaml
apiVersion: apiserver.config.k8s.io/v1
kind: AdmissionConfiguration
plugins:
- name: ImagePolicyWebhook
  configuration:
    imagePolicy:
      kubeConfigFile: /etc/kubernetes/kube-image-bouncer.yml
      allowTTL: 50
      denyTTL: 50
      retryBackoff: 500
      defaultAllow: false
```

---

### **b. Créer le fichier kubeconfig pour le webhook**

Créez le fichier `/etc/kubernetes/kube-image-bouncer.yml` :

```yaml
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority: /etc/kubernetes/kube-image-bouncer/webhook.pem
    server: https://image-bouncer-webhook.default.svc:443/image_policy
  name: bouncer_webhook
contexts:
- context:
    cluster: bouncer_webhook
    user: api-server
  name: bouncer_validator
current-context: bouncer_validator
preferences: {}
users:
- name: api-server
  user:
    client-certificate: /etc/kubernetes/kube-image-bouncer/apiserver-client.pem
    client-key: /etc/kubernetes/kube-image-bouncer/apiserver-client-key.pem
```

### **c. Copier les fichiers sur le nœud maître**

```bash
sudo mkdir -p /etc/kubernetes/kube-image-bouncer
sudo cp webhook.pem apiserver-client.pem apiserver-client-key.pem /etc/kubernetes/kube-image-bouncer/
# Choisissez soit le JSON soit le YAML pour la configuration d'admission
sudo cp admission_configuration.json /etc/kubernetes/
# ou
sudo cp admission_configuration.yaml /etc/kubernetes/
```

---

## **5. Modifier le manifest du kube-apiserver**

Le manifest du kube-apiserver se trouve ici :

```bash
/etc/kubernetes/manifests/kube-apiserver.yaml
```

### **a. Activer le contrôleur d'admission**

Ajoutez les flags suivants à la section `command` du conteneur `kube-apiserver` :

```yaml
spec:
  containers:
  - command:
    - kube-apiserver
    - --enable-admission-plugins=...,ImagePolicyWebhook,...
    - --admission-control-config-file=/etc/kubernetes/admission_configuration.json  # ou .yaml
    # Autres flags existants...
```

### **b. Ajouter les volumes hostPath**

Ajoutez les volumes pour monter les fichiers de configuration et les certificats :

```yaml
spec:
  volumes:
  - name: admission-config
    hostPath:
      path: /etc/kubernetes/admission_configuration.json  # ou .yaml
      type: File
  - name: kube-image-bouncer
    hostPath:
      path: /etc/kubernetes/kube-image-bouncer
      type: DirectoryOrCreate
  containers:
  - volumeMounts:
    - name: admission-config
      mountPath: /etc/kubernetes/admission_configuration.json  # ou .yaml
      subPath: admission_configuration.json  # ou .yaml
    - name: kube-image-bouncer
      mountPath: /etc/kubernetes/kube-image-bouncer
```

---

## **6. Redémarrer le kube-apiserver**

Kubeadm gère automatiquement les mises à jour du manifest. Après modification, le kube-apiserver redémarrera automatiquement. Vérifiez les logs pour confirmer :

```bash
kubectl get pods -n kube-system | grep kube-apiserver
kubectl logs kube-apiserver-<pod-id> -n kube-system | grep "admission"
```

---

## **7. Tester le contrôleur d'admission**

- **Créer un pod avec une image versionnée** (exemple : `nginx:1.13.8`) :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-versioned
spec:
  containers:
  - name: nginx
    image: nginx:1.13.8
```

- **Créer un pod avec une image `latest**` (doit être rejeté) :

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-latest
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

- **Vérifier les logs** du pod du webhook pour confirmer le rejet des images `latest` :

```bash
kubectl logs -l app=image-bouncer-webhook
```

---

## **8. Points d'attention**

- **Montage des certificats** : Le Deployment utilise `/certs/tls.key` et `/certs/tls.crt`, qui sont automatiquement mappés depuis le Secret `tls-image-bouncer-webhook`.
- **Haute disponibilité** : Le Deployment utilise 2 réplicas pour éviter les interruptions de service.
- **Certificats** : Assurez-vous que le nom du certificat (`CN=image-bouncer-webhook.default.svc`) correspond au nom du service Kubernetes.
- **Chicken-egg problem** : Si le webhook est indisponible, toutes les images seront rejetées (si `defaultAllow: false`). Assurez-vous que le webhook est déployé et fonctionnel avant de redémarrer le kube-apiserver.
- **Format de configuration** : Pour Kubernetes ≥ 1.19, le format YAML est recommandé. Pour les versions antérieures, utilisez le format JSON.

---

## **Résumé des fichiers nécessaires**

- `webhook.pem`, `webhook-key.pem` : Certificats pour le serveur webhook.
- `apiserver-client.pem`, `apiserver-client-key.pem` : Certificats pour le client API server.
- `/etc/kubernetes/admission_configuration.json` ou `.yaml` : Configuration du contrôleur d'admission.
- `/etc/kubernetes/kube-image-bouncer.yml` : Fichier kubeconfig pour le webhook.
- `image-bouncer-deployment.yaml` : Déploiement du webhook en tant que Deployment Kubernetes.