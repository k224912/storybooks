PROJECT_ID = storybook-take-1
ZONE=us-central1-a

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
terraform-create-workspace:check-env
	cd terraform && \
		terraform workspace new $(ENV)

terraform-init:check-env
	cd terraform && \
		terraform workspace select $(ENV) && \
		terraform init

TF_ACTION?=plan
terraform-action:check-env 
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

check-env:
ifndef ENV
	$(error ENV is undefined)
endif


GITHUB_SHA?=latest
LOCAL_TAG=storybooks-app:$(GITHUB_SHA)
REMOTE_TAG=gcr.io/$(PROJECT_ID)/$(LOCAL_TAG)

CONTAINER_NAME=storybooks-api




ssh:check-env
	gcloud compute ssh $(SSH_STRING)\
		--project=$(PROJECT_ID) \
		--zone=$(ZONE)

ssh-cmd:check-env
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



deploy:check-env
	$(MAKE) ssh-cmd CMD='docker-credential-gcr configure-docker'
	@echo "pulling new container image..."
	$(MAKE) ssh-cmd CMD='docker pull $(REMOTE_TAG)'
	@echo "removing old container..."
	-$(MAKE) ssh-cmd CMD='docker container stop $(CONTAINER_NAME)'
	-$(MAKE) ssh-cmd CMD='docker container rm $(CONTAINER_NAME)'
	@echo "starting new container..."
ifeq ($(ENV), staging)
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://admin:$(call get-secret,atlas_user_password_$(ENV))@storybooks-$(ENV).7zok6dz.mongodb.net/?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(call get-secret,client_id) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,client_secret) \
			$(REMOTE_TAG) \
			'
else
	@$(MAKE) ssh-cmd CMD='\
		docker run -d --name=$(CONTAINER_NAME) \
			--restart=unless-stopped \
			-p 80:3000 \
			-e PORT=3000 \
			-e \"MONGO_URI=mongodb+srv://production:$(call get-secret,atlas_user_password_$(ENV))@storybooks-$(ENV).vzatk8f.mongodb.net/?retryWrites=true&w=majority\" \
			-e GOOGLE_CLIENT_ID=$(call get-secret,client_id) \
			-e GOOGLE_CLIENT_SECRET=$(call get-secret,client_secret) \
			$(REMOTE_TAG) \
			'
endif


