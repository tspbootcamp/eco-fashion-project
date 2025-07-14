#!/bin/bash

# Organization name
ORG="tspbootcamp"

# Local base directory where all repos will be cloned
BASE_DIR=~/projects/$ORG

# Repositories to process
REPOS=(
  adservice
  cartservice
  checkoutservice
  emailservice
  frontend
  loadgenerator
  paymentservice
  productcatalogservice
  recommendationservice
  redis-cart
  shippingservice
  currencyservice
)

# Step 1: Clone all repos using SSH if not already present
mkdir -p "$BASE_DIR"
cd "$BASE_DIR" || exit 1

for repo in "${REPOS[@]}"; do
  if [ ! -d "$repo" ]; then
    echo "🔄 Cloning $repo..."
    git clone git@github.com:$ORG/$repo.git
  else
    echo "✅ Repo already exists: $repo"
  fi
done

# Step 2: Create CI and K8s files, then commit and push
for repo in "${REPOS[@]}"; do
  REPO_PATH="$BASE_DIR/$repo"
  echo "🔧 Processing $repo..."

  if [ ! -d "$REPO_PATH" ]; then
    echo "❌ Skipping: Directory $REPO_PATH not found."
    continue
  fi

  cd "$REPO_PATH" || continue

  # Create directories
  mkdir -p .github/workflows
  mkdir -p k8s/dev

  # Create CI workflow
  cat > .github/workflows/ci.yml <<EOF
name: CI for $repo

on:
  push:
    branches: [ main ]

env:
  IMAGE_NAME: marypearl/$repo

jobs:
  build-and-push:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3

      - name: Log in to Docker Hub
        uses: docker/login-action@v3
        with:
          username: \${{ secrets.DOCKER_USERNAME }}
          password: \${{ secrets.DOCKER_PASSWORD }}

      - name: Build and push Docker image
        uses: docker/build-push-action@v5
        with:
          context: ./src
          push: true
          tags: |
            marypearl/$repo:latest
            marypearl/$repo:\${{ github.sha }}
EOF

  # Create K8s deployment
  cat > k8s/dev/deployment.yaml <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: $repo
  namespace: default
spec:
  replicas: 1
  selector:
    matchLabels:
      app: $repo
  template:
    metadata:
      labels:
        app: $repo
    spec:
      containers:
        - name: $repo
          image: marypearl/$repo:latest
          ports:
            - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: $repo
  namespace: default
spec:
  selector:
    app: $repo
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: ClusterIP
EOF

  # Commit and push if there are changes
  git add .github/workflows/ci.yml k8s/dev/deployment.yaml

  if git diff --cached --quiet; then
    echo "⚠️  No changes to commit for $repo."
  else
    git commit -m "Add CI workflow and K8s deployment for $repo"
    git push origin main
    echo "✅ Changes pushed for $repo"
  fi

done
