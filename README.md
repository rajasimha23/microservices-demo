<!-- <p align="center">
<img src="/src/frontend/static/icons/Hipster_HeroLogoMaroon.svg" width="300" alt="Online Boutique" />
</p> -->
![Continuous Integration](https://github.com/GoogleCloudPlatform/microservices-demo/workflows/Continuous%20Integration%20-%20Main/Release/badge.svg)

**Online Boutique** is a cloud-first microservices demo application.  The application is a
web-based e-commerce app where users can browse items, add them to the cart, and purchase them.


## Architecture

**Online Boutique** is composed of 11 microservices written in different
languages that talk to each other over gRPC.

[![Architecture of
microservices](/docs/img/architecture-diagram.png)](/docs/img/architecture-diagram.png)

Find **Protocol Buffers Descriptions** at the [`./protos` directory](/protos).

| Service                                              | Language      | Description                                                                                                                       |
| ---------------------------------------------------- | ------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| [frontend](/src/frontend)                           | Go            | Exposes an HTTP server to serve the website. Does not require signup/login and generates session IDs for all users automatically. |
| [cartservice](/src/cartservice)                     | C#            | Stores the items in the user's shopping cart in Redis and retrieves it.                                                           |
| [productcatalogservice](/src/productcatalogservice) | Go            | Provides the list of products from a JSON file and ability to search products and get individual products.                        |
| [currencyservice](/src/currencyservice)             | Node.js       | Converts one money amount to another currency. Uses real values fetched from European Central Bank. It's the highest QPS service. |
| [paymentservice](/src/paymentservice)               | Node.js       | Charges the given credit card info (mock) with the given amount and returns a transaction ID.                                     |
| [shippingservice](/src/shippingservice)             | Go            | Gives shipping cost estimates based on the shopping cart. Ships items to the given address (mock)                                 |
| [emailservice](/src/emailservice)                   | Python        | Sends users an order confirmation email (mock).                                                                                   |
| [checkoutservice](/src/checkoutservice)             | Go            | Retrieves user cart, prepares order and orchestrates the payment, shipping and the email notification.                            |
| [recommendationservice](/src/recommendationservice) | Python        | Recommends other products based on what's given in the cart.                                                                      |
| [adservice](/src/adservice)                         | Java          | Provides text ads based on given context words.                                                                                   |
| [loadgenerator](/src/loadgenerator)                 | Python/Locust | Continuously sends requests imitating realistic user shopping flows to the frontend.                                              |

## Screenshots

| Home Page                                                                                                         | Checkout Screen                                                                                                    |
| ----------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------ |
| [![Screenshot of store homepage](/docs/img/online-boutique-frontend-1.png)](/docs/img/online-boutique-frontend-1.png) | [![Screenshot of checkout screen](/docs/img/online-boutique-frontend-2.png)](/docs/img/online-boutique-frontend-2.png) |



# Project Setup

Ensure you have the following requirements:

Install kubectl - [here](<https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/>).

Install AWS CLI - [here](<https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions>).


### 1. Clone the Repository

```bash
git clone https://github.com/rajasimha23/microservices-demo.git
```
---

### 2. Provision Resources Using Terraform

```bash
cd terraform/modules/dev
terraform init
terraform plan
terraform apply --auto-approve
```
[Here's the list of all resources that might be created ](<https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest?tab=resources>)

---
### 3. Connect kubectl to the cluster

```bash
aws configure
aws eks update-kubeconfig --name <cluster-name> --region <region>
```

**Verify Connection**
```bash
kubectl get nodes
```

---

### 4. Set Up Argo CD on the Cluster

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```



##### Change the Argo CD Service Type to LoadBalancer
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
```

Wait for your cloud provider to assign an external IP:

```bash
kubectl get svc -n argocd -o wide
```

Then, open the **external IP** in your browser to access the Argo CD login page.  
Refer to the official docs: [Argo CD Access Guide](https://argo-cd.readthedocs.io/en/stable/getting_started/#3-access-the-argo-cd-api-server)

**Login to Argo CD**

**Username:** `admin`  
**Password:** Retrieve it from the secret:

```bash
kubectl get secret -n argocd argocd-initial-admin-secret -o=jsonpath='{.data.password}' | base64 -d
```

---

### 5. Create Applications on Argo CD

You can create applications manually via the UI or by applying a manifest. 
 
JSON configuration:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: microservices-demo-dev
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/rajasimha23/microservices-demo.git'
    targetRevision: dev
    path: helm-chart
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: dev
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Wait for the all pods to be running and healthy

   ```sh
   kubectl get pods
   ```

   After a few minutes, you should see the Pods in a `Running` state:

   ```
   NAME                                     READY   STATUS    RESTARTS   AGE
   adservice-76bdd69666-ckc5j               1/1     Running   0          2m58s
   cartservice-66d497c6b7-dp5jr             1/1     Running   0          2m59s
   checkoutservice-666c784bd6-4jd22         1/1     Running   0          3m1s
   currencyservice-5d5d496984-4jmd7         1/1     Running   0          2m59s
   emailservice-667457d9d6-75jcq            1/1     Running   0          3m2s
   frontend-6b8d69b9fb-wjqdg                1/1     Running   0          3m1s
   loadgenerator-665b5cd444-gwqdq           1/1     Running   0          3m
   paymentservice-68596d6dd6-bf6bv          1/1     Running   0          3m
   productcatalogservice-557d474574-888kr   1/1     Running   0          3m
   recommendationservice-69c56b74d4-7z8r5   1/1     Running   0          3m1s
   redis-cart-5f59546cdd-5jnqf              1/1     Running   0          2m58s
   shippingservice-6ccc89f8fd-v686r         1/1     Running   0          2m58s
   ```
Access the web frontend in a browser using the frontend's external IP.

   ```sh
   kubectl get service frontend-6b8d69b9fb-wjqdg  | awk '{print $4}'
   ```

   Visit `http://EXTERNAL_IP` in a web browser to access your instance of Online Boutique.

---

### 6. Monitoring: Deploying Prometheus and Grafana

Create 2 more applications to deploy **Prometheus** and **Grafana** as Argo CD applications on the cluster

- For **Prometheus:** use the repo [here](<https://github.com/prometheus-operator/prometheus-operator>)  
- For **Grafana:** use the repo [here](<https://github.com/grafana/helm-charts>)

###  Access the Grafana Dashboard

#### **Step 1: Check Grafana Service**
List all services in the Grafana namespace (for example `monitoring` or `grafana`):

```bash
kubectl get svc -n grafana
```

Look for the **grafana service** - it’s usually named `grafana` or `kube-prometheus-stack-grafana`.



#### **Step 2: Expose Grafana**

If the Grafana service type is **ClusterIP**, you can either:
- Port-forward it to your local machine, **or**
- Change it to a **LoadBalancer** type to access it externally.

#### Option 1: Port-forward (Local Access)
```bash
kubectl port-forward svc/grafana -n grafana 3000:80
```
Then open your browser and go to:  
👉 [http://localhost:3000](http://localhost:3000)

#### Option 2: LoadBalancer (External Access)
```bash
kubectl patch svc grafana -n grafana -p '{"spec": {"type": "LoadBalancer"}}'
```
Wait for the external IP:
```bash
kubectl get svc -n grafana -o wide
```
Open the external IP in your browser.


#### **Step 3: Get Grafana Admin Credentials and Login**

The admin credentials are stored in a secret.  
Use this command to retrieve them:

```bash
kubectl get secret -n grafana grafana -o jsonpath="{.data.admin-user}" | base64 -d; echo
kubectl get secret -n grafana grafana -o jsonpath="{.data.admin-password}" | base64 -d; echo
```
Login using username and password

---

#### 10. Apply Alert rules
```
kubectl apply -f alert-rules.yaml
kubectl apply -f config.yaml
```
<<<<<<< HEAD

## Clean up

To avoid incurring charges to your AWS account for the resources used in this sample application, delete the individual resources.

To remove the individual resources created for by Terraform:

1. Navigate to the `terraform/` directory.
   ```
   cd microservices-demo/terraform
   ```


2. Run the following command:

   ```bash
   terraform destroy
   ```

   1. If there is a confirmation prompt, type `yes` and hit Enter.
=======
>>>>>>> 94cc9f55895138681aa8e029d2a34a5b64405766
