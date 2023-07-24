# Getting Started

## Dev
```shell
docker compose up -d
docker compose exec app go run main.go
```

## Build for Prod
```shell:
# ECR作成
aws ecr create-repository --repository-name go-dev-repo

# イメージビルド
docker build --no-cache --target runner -t go-dev-repo --platform linux/amd64 -f ./.docker/go/Dockerfile .
```

## Terraform Command

```shell
# コンテナを立ち上げる
docker run \
  -v ~/.aws:/root/.aws \
  -v $(pwd):/terraform \
  -w /terraform \
  -it \
  --entrypoint=ash \
  hashicorp/terraform:1.5

# 初期化
terraform init

# 差分検出
terraform plan

# コードを適用する
terraform apply -auto-approve

# フォーマット
terraform fmt -recursive

# 削除
terraform destroy
```

# Apache Bench

```shell
$ ab -n 10 -c 10 http://localhost:8080/db/1
$ ab -n 10 -c 10 http://localhost:8080/cache/1
```