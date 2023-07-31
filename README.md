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

```shell
# ECR作成
aws ecr create-repository --repository-name go-dev-repo

# ログイン
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com

# イメージビルド
docker build --no-cache --target runner -t go-dev-repo --platform linux/amd64 -f ./.docker/go/Dockerfile .

# タグ付け
docker tag go-dev-repo:latest <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com/go-dev-repo:latest

# プッシュ
docker push <account_id>.dkr.ecr.ap-northeast-1.amazonaws.com/go-dev-repo:latest
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
  -v $(pwd)/.infrastructure:/terraform \
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
  --target "<terraformコマンドで実行後に出力されるbastion_ec2_idを転記>" \
  --document-name AWS-StartPortForwardingSessionToRemoteHost \
  --parameters \
'{
  "host": ["<terraformコマンドで実行後に出力されるDB_HOSTを転記>"],
  "portNumber": ["3306"],
  "localPortNumber":["3306"]
}'

# 以下が表示されたらタブは開いたままにする
> Waiting for connections...
```

```shell
# 別タブでDocker起動
docker run --name mysql-client --rm -it mysql:8.0 /bin/bash

# MySQLクライアントで接続
mysql -h host.docker.internal -P 3306 -u admin -p

# パスワード入力
Enter password: <terraformコマンドで実行後に出力されるDB_PASSを転記>

# 初期クエリ
mysql> <.docker/mysql/init/1_create.sqlの内容を転記>
```

### Systems Manager Parameterに環境変数を格納

```shell
# terraformコマンドで実行後に出力される内容を転記
DB_USER=admin
DB_PASS=xxxxxxx
DB_HOST=go-api.xxxxxxx.ap-northeast-1.rds.amazonaws.com
DB_NAME=golang
DB_PORT=3306
CACHE_HOST1=go-api-dev-memcached-cluster.xxxxxxx.0001.apne1.cache.amazonaws.com:11211
CACHE_HOST2=go-api-dev-memcached-cluster.xxxxxxx.0002.apne1.cache.amazonaws.com:11211
```

### デプロイ

```shell
# デプロイ
aws ecs update-service --cluster go-api --service go-api --task-definition go-api --force-new-deployment

# ステータス確認
aws ecs describe-services --cluster go-api --services go-api --query 'services[*].status' --output text

> ACTIVE
```