# 🔐 Kubernetes HTTPS Setup with Cert-Manager and Let's Encrypt (Route 53 DNS)

This document describes how to secure a custom domain (`dev.charlesabe.com`) using **cert-manager**, **Let’s Encrypt**, and **Ingress NGINX** with DNS challenge via AWS Route 53.

---

## 1. Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/latest/download/cert-manager.yaml


----------- 2 Create AWS Credentials Secret

apiVersion: v1
kind: Secret
metadata:
  name: route53-credentials-secret
  namespace: cert-manager
type: Opaque
stringData:
  AWS_ACCESS_KEY_ID: <your-access-key>
  AWS_SECRET_ACCESS_KEY: <your-secret-key>


--------- 3 Create ClusterIssuer for Let’s Encrypt

apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-dns
spec:
  acme:
    email: your@email.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-dns-private-key
    solvers:
    - dns01:
        route53:
          region: ca-central-1
          accessKeyIDSecretRef:
            name: route53-credentials-secret
            key: AWS_ACCESS_KEY_ID
          secretAccessKeySecretRef:
            name: route53-credentials-secret
            key: AWS_SECRET_ACCESS_KEY


------ 4 Install Ingress NGINX Controller

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
kubectl create namespace ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.publishService.enabled=true


---------- 5. Point Route 53 to Ingress Load Balancer

In AWS Route 53:

Create A/ALIAS record for dev.charlesabe.com

Target → ELB DNS from kubectl get svc -n ingress-nginx


--------6. Create Ingress with TLS and Auto Certificate

apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: example-ingress
  namespace: default
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-dns
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - dev.charlesabe.com
    secretName: dev-charlesabe-com-tls
  rules:
  - host: dev.charlesabe.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80


---------7. Verify HTTPS
curl -v https://dev.charlesabe.com

Or test on SSL Labs



