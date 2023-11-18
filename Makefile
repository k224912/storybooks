PROJECT_ID = storybook-take-1
run-local:
	docker-compose up
###
create-tf-backend-bucket:
	gsutil mb -p $(PROJECT_ID) gs://$(PROJECT_ID)-terraform