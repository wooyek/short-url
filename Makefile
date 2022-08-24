IMAGE ?= shorts
DEPLOYMENT_WEB ?= ${IMAGE}-web
REGISTRY ?= registry.digitalocean.com/wooyek

default: help

help:  ## Show help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-10s\033[0m %s\n", $$1, $$2}'

build:  ## Build the web app wheel and docker image
	poetry build
	poetry export --without-hashes -o dist/requirements.txt
	docker build --tag ${IMAGE} .

push: build  ## Publish web app image to a registry
	docker tag ${IMAGE} ${REGISTRY}/${IMAGE}
	docker push ${REGISTRY}/${IMAGE}

run:  ## Start docker image with the web app
	docker run -it --rm -p 80:80 --name ${IMAGE} ${IMAGE}

up: build  ## Start env with docker compose
	docker-compose up

create-deployment:  ## Create and setup k8s deployment
	kubectl create deployment ${DEPLOYMENT_WEB} --image=${REGISTRY}/${IMAGE}
	kubectl scale deployment/${DEPLOYMENT_WEB} --replicas=3
	kubectl expose deployment ${DEPLOYMENT_WEB} --type=LoadBalancer --port=80 --target-port=80
	kubectl patch deployment/${DEPLOYMENT_WEB} --type='json' --patch='[{"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [{"name": "REDIS_PASSWORD", "valueFrom": {"secretKeyRef": {"key": "redis-password", "name": "shorts-redis"}}}]}]'

delete-deployment:  ## Remove k8s deployment
	kubectl delete deployment/${DEPLOYMENT_WEB}
	kubectl delete services/${DEPLOYMENT_WEB}

deploy: push  ## Restart k8s deployment
	kubectl rollout history deployment/${DEPLOYMENT_WEB}
	kubectl rollout restart deployment/${DEPLOYMENT_WEB}
	kubectl rollout status -w deployment/${DEPLOYMENT_WEB}

minikube-push: build  ## Load local image into minikube image registry
	minikube image load ${IMAGE}
	minikube image ls

minikube-create-deployment: minikube-push create-deployment  # Create and setup k8s deployment on minikube
	kubectl patch deployment/${DEPLOYMENT_WEB} --type='json' --patch='[{"op": "replace", "path": "/spec/template/spec/containers/0/imagePullPolicy", "value": "Never"}]'

minikube-load-balancer:
	@echo "--------------------------------------"
	@echo "Please lookup EXTERNAL-IP column"
	@echo "If it's pending start: minikube tunnel"
	@echo "--------------------------------------"
	kubectl get services ${DEPLOYMENT_WEB}

do-load-balancer:
	doctl compute load-balancer list --format Name,Created,IP,Status
