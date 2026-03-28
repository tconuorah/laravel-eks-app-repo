# laravel-eks-gitops-repo

This directory is the scaffold for the separate GitOps repository that Argo CD should watch.

## Structure

```text
bootstrap/                 One-time Argo CD bootstrap manifest
clusters/dev/              AppProject and child Applications for the dev cluster
platform/external-secrets/ ClusterSecretStore manifests
workloads/dev/laravel/     Laravel environment secret manifests
```

## Bootstrap flow

1. Create a new GitHub repository named `laravel-eks-gitops-repo`.
2. Push the contents of this directory to that new repository.
3. Apply Terraform from `terraform/envs/dev` in the source repo to install Argo CD, External Secrets Operator, IAM, and AWS Secrets Manager resources.
4. Apply `bootstrap/root-application.yaml` to the cluster:

```bash
kubectl apply -n argocd -f bootstrap/root-application.yaml
```

5. Argo CD will then sync the `dev` project, the External Secrets store, the Laravel ExternalSecret, and the Laravel Helm application.

## Notes

- The bootstrap manifest assumes the GitOps repo lives at `https://github.com/tconuorah/laravel-eks-gitops-repo.git`.
- The Laravel application source repo is pinned in Argo CD to `https://github.com/tconuorah/laravel-eks-deploy-gitops.git`.
- The Laravel runtime secret is sourced from AWS Secrets Manager secret `php-nginx-app-dev/laravel/runtime`.
- If you keep the GitOps repo private, create Argo CD repo credentials before applying the root application.
