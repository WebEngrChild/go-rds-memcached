# Getting Started

## Dev編
```shell
docker compose up -d
docker compose exec app go run main.go
```
### Apache Benchを使った検証

```shell
ab -n 10 -c 10 http://localhost:8080/db/1
ab -n 10 -c 10 http://localhost:8080/cache/1
```

## AWS編

### ECR構築
```shell:
# ECR作成
aws ecr create-repository --repository-name go-dev-repo

# イメージビルド
docker build --no-cache --target runner -t go-dev-repo --platform linux/amd64 -f ./.docker/go/Dockerfile .
```

### Systems Manager Parameterの初期値設定

```shell
aws ssm put-parameter \
    --name "/env" \
    --value "init" \
    --type SecureString
```

### Terraformでリソース構築

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

### Systems Manager Port fordingでRDSに接続

```shell
# セッション開始
aws ssm start-session \
  --target "<.tfstateのaws_instanceのidを転記>" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters \
'{
  "host": ["<.tfstateのaws_db_instanceのaddressを転記>"],
  "portNumber": ["3306"],
  "localPortNumber":["3306"]
}'
```

```shell
# Docker起動
docker run --name mysql-client --rm -it mysql:8.0 /bin/bash

# MySQLクライアントで接続
mysql -h host.docker.internal -P 3306 -u admin -p
Enter password: <.tfstateのrandom_string.db_password.resultを入力>
mysql> <1_create.sqlの内容を転記>
```

### Systems Manager Parameterに環境変数を格納

```shell
DB_PASS=<.tfstateのrandom_string.db_password.resultを入力>
DB_HOST=<.tfstateのaws_db_instanceのaddressを転記>
```