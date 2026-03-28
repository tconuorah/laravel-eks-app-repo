# Laravel on EKS with Helm, ECR, ALB, and RDS

This repository provisions AWS infrastructure with Terraform and deploys a Laravel application to EKS with Helm.

It now includes a working setup for:

- Laravel application source in `app/`
- `nginx` and `php-fpm` Docker images
- ECR image push workflow
- Helm deployment via `laravel-helm/`
- ALB ingress on EKS
- RDS MySQL connectivity with TLS trust
- Terraform-based AWS infrastructure
- Secret handling through `laravel-helm/values.secret.yaml`

## Repository Layout

```text
app/                 Laravel application source
docker/nginx/        nginx image build
docker/php/          php-fpm image build
laravel-helm/        Helm chart
scripts/             helper scripts
terraform/           AWS infrastructure
```

## What We Did

### 1. Fixed and completed the Helm chart

We reviewed and corrected the Helm chart and added missing templates:

- `templates/configmap-nginx.yaml`
- `templates/secret.yaml`
- `templates/pdb.yaml`

We also fixed formatting and deployment wiring so the chart renders and deploys correctly.

Later, the chart was renamed from `laravel` to `laravel-helm`.

### 2. Replaced the placeholder app with the real Laravel app

Originally the deployment served a placeholder PHP page. We updated the repo so the real Laravel app is now built from:

```text
app/
```

We also cleaned up the repo structure by removing the old `platform-engine` directory and the earlier placeholder app folder.

### 3. Updated Dockerfiles

We updated:

- `docker/php/Dockerfile`
- `docker/nginx/Dockerfile`

So that they build and serve the real Laravel application instead of the placeholder app.

### 4. Added ECR push workflow

We used:

```bash
./scripts/push-ecr-images.sh
```

to build and push the `nginx` and `php` images to ECR.

### 5. Added secret-based values handling

We created:

- `laravel-helm/values.secret.yaml`
- `laravel-helm/values.secret.yaml.example`

This keeps sensitive values such as:

- `APP_KEY`
- DB host
- DB password
- MySQL SSL CA path

out of the main Helm values file.

### 6. Connected Laravel to RDS

We configured the application to connect to the RDS instance through Helm secret values and verified the connection by running migrations successfully.

### 7. Added proper RDS TLS trust

We updated the PHP image so it includes the official Amazon RDS CA bundle and configured Laravel/MySQL to trust it using:

```text
MYSQL_ATTR_SSL_CA=/etc/mysql/certs/rds-global-bundle.pem
```

## Issues We Ran Into and How We Solved Them

### Issue: `ImagePullBackOff`

The app pods failed to start because the images had not been pushed to ECR yet.

Fix:
- built the images
- pushed them to ECR
- updated Helm to use the correct image tags

### Issue: ALB ingress failed with `UnauthorizedOperation`

The AWS Load Balancer Controller could not create security groups.

Cause:
- incomplete IAM policy for the ALB controller IRSA role

Fix:
- updated the ALB controller IAM policy in Terraform

### Issue: ALB ingress failed with target group port errors

Cause:
- ALB was reconciling in the wrong target mode for the `ClusterIP` service

Fix:
- configured ingress to use ALB target type `ip`

### Issue: App showed only a placeholder page

Cause:
- Dockerfiles were still building the temporary placeholder app

Fix:
- updated Dockerfiles to build the real Laravel app from `app/`

### Issue: Laravel app returned HTTP 500

Cause:
- missing `APP_KEY`

Fix:
- generated a Laravel `APP_KEY`
- stored it in `laravel-helm/values.secret.yaml`
- redeployed the app

### Issue: `php artisan migrate` failed with MySQL socket error

Error:
- `SQLSTATE[HY000] [2002] No such file or directory`

Cause:
- Laravel was not using the RDS hostname yet and was trying a local socket

Fix:
- added DB settings to `values.secret.yaml`
- redeployed
- cleared Laravel config cache

### Issue: DB connection still hung

Cause:
- RDS security group allowed the wrong traffic source

Fix:
- updated Terraform so RDS allows traffic from the EKS private app subnets

### Issue: MySQL CLI failed with TLS certificate verification error

Error:
- `TLS/SSL error: Certificate verification failure: The certificate is NOT trusted.`

Cause:
- the container did not trust the Amazon RDS CA

Fix:
- downloaded the official Amazon RDS global CA bundle into the PHP image
- configured MySQL client trust
- exposed `MYSQL_ATTR_SSL_CA` to Laravel through Helm secret values

## Prerequisites

- AWS CLI configured for the target account
- Docker
- kubectl
- Helm
- Terraform

## Infrastructure

The main Terraform environment is:

```bash
terraform/envs/dev
```

To create or update infrastructure:

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
```

## Secrets

Use the local secret values file:

```text
laravel-helm/values.secret.yaml
```

Example:

```yaml
app:
  key: "base64:replace-with-laravel-app-key"
  dbHost: "your-rds-endpoint.us-east-2.rds.amazonaws.com"
  dbPort: "3306"
  dbName: "laravel"
  dbUser: "root"
  dbPassword: "replace-with-db-password"
  mysqlAttrSslCa: "/etc/mysql/certs/rds-global-bundle.pem"
```

## Build and Push Images

Build and push both images to ECR:

```bash
TAG=20260314-ssl1 ./scripts/push-ecr-images.sh
```

You can also use any tag you want:

```bash
TAG=1.0.1 ./scripts/push-ecr-images.sh
```

## Argo CD and GitOps

The Terraform `dev` environment now provisions:

- Argo CD in the `argocd` namespace
- External Secrets Operator in the `external-secrets` namespace
- an AWS Secrets Manager secret for Laravel runtime environment values
- IRSA permissions so External Secrets can read that secret

A separate GitOps repository scaffold is included locally at:

```text
laravel-eks-gitops-repo/
```

Push that directory to a new GitHub repository named `laravel-eks-gitops-repo`, then bootstrap Argo CD with:

```bash
kubectl apply -n argocd -f laravel-eks-gitops-repo/bootstrap/root-application.yaml
```

The workflow:

- `.github/workflows/ci.yml` builds and pushes the `php` and `nginx` images to ECR using the commit SHA as an immutable tag
- `.github/workflows/promote-gitops-dev.yml` updates `clusters/dev/app-laravel.yaml` in a GitOps repo branch and opens a PR after a successful `ci` run on `dev`

For GitOps promotion with a GitHub App, create and install a GitHub App on `laravel-eks-gitops-repo`, then set these GitHub Actions settings in this source repo:

- Variable: `GITOPS_APP_ID`
- Variable: `GITOPS_REPO_FULL_NAME` (example: `tconuorah/laravel-eks-gitops-repo`)
- Variable: `GITOPS_REPO_DEFAULT_BRANCH` (optional, defaults to `main`)
- Secret: `GITOPS_APP_PRIVATE_KEY`

The GitHub App should have:

- Repository permissions: `Contents` = `Read and write`
- Repository permissions: `Pull requests` = `Read and write`
- Installation target: the `laravel-eks-gitops-repo` repository

The Laravel workload reads secrets from AWS Secrets Manager through:

```text
laravel-eks-gitops-repo/workloads/dev/laravel/externalsecret.yaml
```

## GitHub Actions ECR Role

Terraform now includes a reusable IAM module at:

```text
terraform/modules/iam-github-ecr-push
```

The `dev` environment creates a GitHub OIDC role that can push to every ECR repository created by `var.ecr_repositories`.

Apply Terraform and copy the role ARN:

```bash
cd terraform/envs/dev
terraform output -raw github_ecr_push_role_arn
```

Set these GitHub repository variables before using the workflow:

- `AWS_GITHUB_ACTIONS_ROLE_ARN`
- `AWS_REGION` (optional, defaults to `us-east-2`)
- `ECR_PHP_REPOSITORY` (optional, defaults to `php`)
- `ECR_NGINX_REPOSITORY` (optional, defaults to `nginx`)

By default the role trusts the `tconuorah/laravel-eks-app-repo` repository on `refs/heads/dev`. Update `github_repository` or `github_allowed_refs` in `terraform/envs/dev/variables.tf` if your repo or branch changes.

If your AWS account already has the GitHub OIDC provider, set:

- `create_github_oidc_provider = false`
- `github_oidc_provider_arn = "arn:aws:iam::<account-id>:oidc-provider/token.actions.githubusercontent.com"`

## Deploy with Helm

Deploy or upgrade the application:

```bash
helm upgrade --install laravel ./laravel-helm -n laravel \
  --create-namespace \
  -f laravel-helm/values.secret.yaml \
  --set image.nginx.tag=20260314-ssl1 \
  --set image.php.tag=20260314-ssl1
```

Check rollout:

```bash
kubectl rollout status deployment/laravel -n laravel
kubectl get pods -n laravel
kubectl get ingress -n laravel
```

## Database Commands

Clear Laravel caches after DB config changes:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan optimize:clear
```

Run migrations:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan migrate --force
```

Check migration status:

```bash
kubectl exec -n laravel deploy/laravel -c php -- php artisan migrate:status
```

List database tables from inside the container:

```bash
kubectl exec -n laravel deploy/laravel -c php -- sh -lc 'mysql -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD" "$DB_DATABASE" -e "show tables;"'
```

## RDS TLS

The PHP image includes the official Amazon RDS global CA bundle at:

```text
/etc/mysql/certs/rds-global-bundle.pem
```

Laravel uses:

```text
MYSQL_ATTR_SSL_CA=/etc/mysql/certs/rds-global-bundle.pem
```

This allows both Laravel and the MySQL client to connect to RDS with trusted TLS.

Official AWS references:

- https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/UsingWithRDS.SSL.html
- https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem

## Troubleshooting

### `ImagePullBackOff`

Usually means the image tag has not been pushed to ECR yet.

Fix:

```bash
TAG=<tag> ./scripts/push-ecr-images.sh
helm upgrade --install laravel ./laravel-helm -n laravel -f laravel-helm/values.secret.yaml \
  --set image.nginx.tag=<tag> \
  --set image.php.tag=<tag>
```

### ALB ingress has no address

Check:

```bash
kubectl describe ingress -n laravel laravel
kubectl logs -n kube-system deployment/aws-load-balancer-controller
```

Common causes:

- missing IAM permissions for the ALB controller
- wrong ingress target type

### Laravel returns HTTP 500

Check logs:

```bash
kubectl logs -n laravel deployment/laravel -c php
kubectl logs -n laravel deployment/laravel -c nginx
```

Common causes:

- missing `APP_KEY`
- wrong DB values
- stale Laravel config cache

### DB connection problems

Check environment variables inside the pod:

```bash
kubectl exec -n laravel deploy/laravel -c php -- printenv | grep '^DB_'
```

Test connectivity:

```bash
kubectl exec -n laravel deploy/laravel -c php -- sh -lc 'mysqladmin ping -h "$DB_HOST" -P "$DB_PORT" -u "$DB_USERNAME" -p"$DB_PASSWORD"'
```

If Laravel migrations work but the MySQL CLI fails with TLS trust errors, rebuild and redeploy the updated PHP image.

## Destroying Infrastructure

Remove the app first so the ALB can clean up gracefully:

```bash
helm uninstall laravel -n laravel
kubectl delete namespace laravel --wait=true
```

Then destroy the main infrastructure:

```bash
cd terraform/envs/dev
terraform init
terraform destroy
```

If you also want to remove the Terraform backend infrastructure, do that last:

```bash
cd terraform/bootstrap
terraform init
terraform destroy
```

Only destroy `terraform/bootstrap` if you want to remove the backend state infrastructure too.
