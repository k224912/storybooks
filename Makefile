PROJECT_ID = storybook-take-1
ZONE=us-central1-a
PYTHON := C:\Users\HP\AppData\Local\Microsoft\WindowsApps\

run-local:
	docker-compose up
###
create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform


###
define get-secret
$(shell gcloud secrets versions access latest --secret=$(1) --project=$(PROJECT_ID))
endef

###
ENV=staging
terraform-create-workspace:
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init:
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan
terraform-action: 
	@cd terraform && \
		terraform workspace select $(ENV) && \
		terraform $(TF_ACTION) \
		-var-file="./environments/common.tfvars" \
		-var-file="./environments/$(ENV)/config.tfvars"\
		-var="mongodbatlas_private_key=$(call get-secret,mongodbatlas_private_key)" \
		-var="atlas_user_password=$(call get-secret,atlas_user_password_$(ENV))" \
		-var="cloudflare_api_token=$(call get-secret,cloudflare_api_token)"\
		-var="cloudflare_zone_id=$(call get-secret,cloudflare_zone_id)"



###
SSH_STRING=HP@storybooks-vm-$(ENV)

GITHUB_SHA?=latest
LOCAL_TAG=storybooks-app:$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=storybooks-api
DB_NAME=storybooks
dockerdeploycommand='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://storybooks-user-(ENV):$(call get-secret,atlas_user_password_$(ENV))@storybooks-(ENV).bgnfej6.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(call get-secret,client_id) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,client_secret) \
			$(REMOTE_TAG) \
			'



ssh:
	gcloud compute ssh $(SSH_STRING)\
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd:
	@gcloud compute ssh $(SSH_STRING)\
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)\
		--command="$(CMD)"
#building the docker image before pushing it to the registry
build:
	docker build -t $(LOCAL_TAG) .



push:
	docker tag $(LOCAL_TAG) $(REMOTE_TAG)
	docker push $(REMOTE_TAG) 

deploy: 
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://storybooks-user-$(ENV):$(call get-secret,atlas_user_password_$(ENV))@storybooks-$(ENV).bgnfej6.mongodb.net/$(DB_NAME)?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(call get-secret,client_secret) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,client_secret) \
			$(REMOTE_TAG) \
			'	


deploy2:
	@$(MAKE) ssh-cmd CMD=$(dockerdeploycommand)

