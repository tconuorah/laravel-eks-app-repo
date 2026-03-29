# Laravel on EKS with Terraform, Helm, Argo CD, ECR, ALB, and RDS

This repository contains everything needed to stand up AWS infrastructure for a Laravel application and deploy it to Amazon EKS.

The recommended end state for this project is:

1. Terraform creates the AWS and cluster infrastructure.
2. GitHub Actions builds and pushes the `php` and `nginx` images to ECR.
3. A separate GitOps repository stores the Argo CD manifests.
4. Argo CD deploys the Helm chart from this repository.
5. External Secrets pulls Laravel runtime secrets from AWS Secrets Manager.

If you need a faster smoke-test path, this repo also supports a direct Helm deployment without Argo CD.

## What Is In This Repo

```text
app/                       Laravel application source
docker/nginx/              nginx container image
docker/php/                php-fpm container image
laravel-helm/              Helm chart for the Laravel workload
laravel-eks-gitops-repo/   Scaffold for the separate GitOps repository
scripts/                   Helper scripts used by automation
terraform/bootstrap/       One-time Terraform state bucket setup
terraform/envs/dev/        Main AWS, EKS, Argo CD, ECR, and RDS environment
```

## Recommended Deployment Flow

Use this order to complete the project:

1. Create the Terraform backend bucket.
2. Update the repo-specific placeholders in Terraform and GitOps manifests.
3. Apply the `dev` Terraform environment.
4. Connect `kubectl` to the new EKS cluster.
5. Push `laravel-eks-gitops-repo/` to its own GitHub repository.
6. Configure GitHub Actions permissions and variables.
7. Bootstrap Argo CD with the GitOps repo.
8. Push a commit to the `dev` branch so CI builds images and opens a GitOps promotion PR.
9. Merge the GitOps PR and let Argo CD sync the application.
10. Verify the app, ingress, secrets, and database connectivity.

## Prerequisites

Install and configure these locally:

- AWS CLI with credentials for the target account
- Terraform `>= 1.6`
- `kubectl`
- Helm
- Docker
- GitHub access for both the app repo and the GitOps repo

You will also need:

- An AWS account
- A public DNS name for the Laravel application
- A GitHub repository for this app source
- A second GitHub repository for the GitOps manifests

## Step 1: Bootstrap the Terraform Backend

The main environment at `terraform/envs/dev` uses an S3 backend, so create that bucket first.

Create `terraform/bootstrap/terraform.tfvars` with values similar to:

```hcl
aws_region               = "us-east-2"
project_name             = "php-nginx-app"
environment              = "bootstrap"
state_bucket_name        = "your-unique-terraform-state-bucket"
state_bucket_force_destroy = true
```

Apply the bootstrap stack:

```bash
cd terraform/bootstrap
terraform init
terraform apply
```

After that, update `terraform/envs/dev/backend.tf` so `bucket`, `key`, and `region` match your backend settings.

## Step 2: Replace the Project Placeholders

Before applying the main stack, update the placeholders that still point to example repos, branches, hosts, and regions.

### Required Terraform values

Create `terraform/envs/dev/terraform.tfvars` and override the defaults you actually plan to use. At minimum, review:

```hcl
aws_region         = "us-east-2"
project_name       = "php-nginx-app"
environment        = "dev"
laravel_hostname   = "laravel-dev.example.com"
github_repository  = "your-org/your-app-repo"
github_allowed_refs = ["refs/heads/dev"]
db_password        = "replace-me"
```

Also review the VPC, subnet, node group, and database defaults in `terraform/envs/dev/variables.tf` and adjust them if they do not fit your AWS account or networking plan.

### Required GitOps manifest updates

Update these files before you push `laravel-eks-gitops-repo/` to its own repository:

- `laravel-eks-gitops-repo/bootstrap/root-application.yaml`
- `laravel-eks-gitops-repo/clusters/dev/project-laravel.yaml`
- `laravel-eks-gitops-repo/clusters/dev/app-laravel.yaml`
- `laravel-eks-gitops-repo/clusters/dev/app-laravel-secret.yaml`
- `laravel-eks-gitops-repo/clusters/dev/app-external-secrets-store.yaml`

Check and replace:

- the app source repo URL
- the GitOps repo URL
- the branch name if you are not using `main`
- the hostname `laravel-dev.example.com`
- the AWS region if you are not using `us-east-2`

If the GitOps repo will stay private, keep `laravel-eks-gitops-repo/bootstrap/private-repo-credentials-secret.example.yaml` handy for Argo CD repository credentials.

## Step 3: Apply the Main Infrastructure

Provision ECR, VPC, EKS, ALB controller, RDS, External Secrets, Argo CD, and the Laravel runtime secret:

```bash
cd terraform/envs/dev
terraform init
terraform plan
terraform apply
```

Useful outputs:

```bash
terraform output -raw cluster_name
terraform output -raw cluster_endpoint
terraform output -raw rds_endpoint
terraform output -raw laravel_runtime_secret_name
terraform output -raw github_ecr_push_role_arn
```

What Terraform creates for you:

- ECR repositories for `php` and `nginx`
- An EKS cluster and node group
- The AWS Load Balancer Controller
- An RDS MySQL instance
- An AWS Secrets Manager secret for Laravel runtime variables
- IRSA for External Secrets
- Argo CD in the `argocd` namespace

The Laravel runtime secret is populated by Terraform with values such as `APP_KEY`, `DB_HOST`, `DB_DATABASE`, and `MYSQL_ATTR_SSL_CA`.

## Step 4: Connect to the Cluster

Configure local Kubernetes access:

```bash
aws eks update-kubeconfig \
  --region <your-aws-region> \
  --name "$(cd terraform/envs/dev && terraform output -raw cluster_name)"
```

Verify cluster access:

```bash
kubectl get nodes
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n external-secrets
```

## Step 5: Create the GitOps Repository

The directory `laravel-eks-gitops-repo/` is a scaffold, not the live GitOps remote yet.

Create a new GitHub repository and push that directory into it:

```bash
cd laravel-eks-gitops-repo
git init
git remote add origin git@github.com:your-org/laravel-eks-gitops-repo.git
git checkout -b main
git add .
git commit -m "Initial GitOps bootstrap"
git push -u origin main
```

The GitOps repo should contain:

- the root Argo CD bootstrap application
- the `AppProject`
- the Laravel application definition
- the External Secret definition
- the External Secrets `ClusterSecretStore`

## Step 6: Configure GitHub Actions

This repo already includes these workflows:

- `.github/workflows/ci.yml`
- `.github/workflows/promote-gitops-dev.yml`

The `ci.yml` workflow:

- runs Laravel checks
- builds the `php` and `nginx` images
- pushes both images to ECR
- tags both images with the first 12 characters of the source commit SHA

The `promote-gitops-dev.yml` workflow:

- runs after successful CI on the `dev` branch
- updates `clusters/dev/app-laravel.yaml` in the GitOps repo
- opens or updates a PR in the GitOps repo

### Required GitHub variables for this source repo

Set these in your GitHub repository settings:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`
- `AWS_REGION`
- `ECR_PHP_REPOSITORY`
- `ECR_NGINX_REPOSITORY`
- `GITOPS_APP_ID`
- `GITOPS_REPO_FULL_NAME`
- `GITOPS_REPO_DEFAULT_BRANCH`

### Required GitHub secret for this source repo

Set:

- `GITOPS_APP_PRIVATE_KEY`

### GitHub App requirements for the GitOps repo

Create and install a GitHub App that can write to the GitOps repository. It needs:

- `Contents: Read and write`
- `Pull requests: Read and write`

### AWS role used by CI

Terraform outputs the OIDC-backed ECR push role ARN:

```bash
cd terraform/envs/dev
terraform output -raw github_ecr_push_role_arn
```

That role trusts the repository defined by `github_repository` and the refs defined by `github_allowed_refs`.

## Step 7: Bootstrap Argo CD

If your GitOps repo is private, create the Argo CD repo credentials first:

```bash
kubectl apply -n argocd \
  -f laravel-eks-gitops-repo/bootstrap/private-repo-credentials-secret.example.yaml
```

Then bootstrap Argo CD with the root application:

```bash
kubectl apply -n argocd \
  -f laravel-eks-gitops-repo/bootstrap/root-application.yaml
```

Check that Argo CD starts reconciling the child applications:

```bash
kubectl get applications -n argocd
kubectl get externalsecret -n laravel
kubectl get secret -n laravel
```

Expected result:

- Argo CD creates the `laravel` namespace
- External Secrets creates the `laravel-env` secret from AWS Secrets Manager
- the Laravel application becomes ready once a valid image tag exists in ECR

## Step 8: Trigger the First Build and Promotion

The application manifest in the GitOps repo contains a pinned commit SHA and image tags. Those are meant to be updated by the promotion workflow.

Push a commit to the `dev` branch of the app source repository:

```bash
git checkout dev
git add .
git commit -m "Trigger first deployment"
git push origin dev
```

Then watch the automation:

1. `ci-nginx-php` runs in the app repo.
2. The workflow pushes `php` and `nginx` images to ECR.
3. `promote-gitops-dev` opens a PR against the GitOps repo.
4. You review and merge that PR.
5. Argo CD syncs the new revision and image tags into the cluster.

## Step 9: Verify the Deployment

Check the workload:

```bash
kubectl get pods -n laravel
kubectl get svc -n laravel
kubectl get ingress -n laravel
kubectl rollout status deployment/laravel -n laravel
```

Inspect logs if needed:

```bash
kubectl logs -n laravel deployment/laravel -c php
kubectl logs -n laravel deployment/laravel -c nginx
```

Verify the database connection:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan migrate:status
```

If you need to run migrations manually:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan migrate --force
```

If config values changed, clear the Laravel caches:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan optimize:clear
```

## Optional: Direct Helm Deployment Instead of GitOps

Use this only if you want a manual deployment path or a quick smoke test and Argo CD is not already managing the same release.

Copy the example secret values file:

```bash
cp laravel-helm/values.secret.yaml.example laravel-helm/values.secret.yaml
```

Fill in the real values in `laravel-helm/values.secret.yaml`, especially:

- `app.key`
- `app.dbHost`
- `app.dbPassword`
- `app.mysqlAttrSslCa`

Deploy with Helm:

```bash
helm upgrade --install laravel ./laravel-helm \
  -n laravel \
  --create-namespace \
  -f laravel-helm/values.secret.yaml
```

If you want to override image tags manually:

```bash
helm upgrade --install laravel ./laravel-helm \
  -n laravel \
  --create-namespace \
  -f laravel-helm/values.secret.yaml \
  --set image.nginx.tag=<tag> \
  --set image.php.tag=<tag>
```

Important:

- This path uses the Kubernetes secret rendered by `laravel-helm/templates/secret.yaml`.
- The recommended GitOps path does not need `laravel-helm/values.secret.yaml` because it reads runtime configuration from AWS Secrets Manager through External Secrets.

## Troubleshooting

### CI cannot push images to ECR

Check:

- the `AWS_GITHUB_ACTIONS_ROLE_ARN` variable
- the value of `github_repository` in `terraform/envs/dev/terraform.tfvars`
- the value of `github_allowed_refs`

### Argo CD syncs, but the Laravel pods do not start

Check:

```bash
kubectl describe pods -n laravel
kubectl get secret -n laravel laravel-env -o yaml
```

Common causes:

- the `ExternalSecret` has not synced yet
- the image tag in the GitOps repo does not exist in ECR
- the hostname or ingress values are still placeholders

### Ingress does not receive an address

Check:

```bash
kubectl describe ingress -n laravel laravel
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

Common causes:

- missing ALB controller permissions
- ALB annotations or hostnames still set to placeholder values

### Database connectivity fails

Check the runtime environment inside the pod:

```bash
kubectl exec -n laravel deploy/laravel -c php -- printenv | grep '^DB_'
kubectl exec -n laravel deploy/laravel -c php -- printenv | grep '^MYSQL_ATTR_SSL_CA'
```

The PHP image already includes the Amazon RDS CA bundle at:

```text
/etc/mysql/certs/rds-global-bundle.pem
```

## Completion Checklist

The project is effectively complete when all of these are true:

- Terraform bootstrap has created the remote state bucket.
- `terraform/envs/dev` applies successfully.
- `kubectl` can reach the EKS cluster.
- The GitOps repo exists and the manifest URLs point to your real repositories.
- GitHub Actions can push both images to ECR.
- The promotion workflow opens a PR against the GitOps repo.
- Argo CD syncs the Laravel application.
- `laravel-env` is created from AWS Secrets Manager.
- The ingress receives an address.
- Laravel can connect to RDS and run migrations.

## Cleanup

If Argo CD is managing the application, remove or disable the GitOps application manifests first so Argo CD does not recreate the release.

Then remove the application:

```bash
helm uninstall laravel -n laravel || true
kubectl delete namespace laravel --wait=true || true
```

Then destroy the main environment:

```bash
cd terraform/envs/dev
terraform init
terraform destroy
```

Destroy the bootstrap backend last, only if you no longer need the Terraform state bucket:

```bash
cd terraform/bootstrap
terraform init
terraform destroy
```
