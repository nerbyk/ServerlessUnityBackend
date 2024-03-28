GAMEPLAY_BACKEND_DIR := ../gameplay_backend
LAMBDA_JOBS_DIR := ${GAMEPLAY_BACKEND_DIR}/jobs
VENDOR_JOBS_DIR := ./vendor/gameplay_backend/jobs
AWS_TEST_ACCOUNT := ferma-deploy

package_gameplay_backend:
	cd ${GAMEPLAY_BACKEND_DIR} && rm -rf vendor/bundle && rm .bundle/config && \
		bundle config set --local without 'development test' && \
		bundle config set --local path 'vendor/bundle' && \
		bundle install
	rm -rf ${VENDOR_JOBS_DIR} && mkdir -p ${VENDOR_JOBS_DIR}
	cp -r ${GAMEPLAY_BACKEND_DIR}/assets ./vendor/gameplay_backend
	cp -r ${LAMBDA_JOBS_DIR}/* ${VENDOR_JOBS_DIR}
	for dir in ${LAMBDA_JOBS_DIR}/*; do \
		cp -r ${GAMEPLAY_BACKEND_DIR}/Gemfile* ${VENDOR_JOBS_DIR}/$$(basename $$dir); \
		cp -r ${GAMEPLAY_BACKEND_DIR}/lib/* ${VENDOR_JOBS_DIR}/$$(basename $$dir); \
		rm -rf ${GAMEPLAY_BACKEND_DIR}/vendor/bundle/ruby/*/gems/aws-sdk-*; \
		cp -r ${GAMEPLAY_BACKEND_DIR}/vendor ${VENDOR_JOBS_DIR}/$$(basename $$dir)/vendor; \
	done


run_infra_lambdas_tests:
	for dir in ./lib/*/lambda/*/; do \
		if [ -e "$$dir/Makefile" ]; then \
			if $(MAKE) -C "$$dir" unit; then \
				echo "Unit tests passed for $$dir"; \
			else \
				echo "Unit tests failed for $$dir"; \
				exit 1; \
			fi; \
			$(MAKE) -C "$$dir" default; \
		fi; \
	done

package: 
	make package_gameplay_backend
	make run_infra_lambdas_tests

deploy_test:
	make package
	aws-vault exec $(AWS_TEST_ACCOUNT) -- cdk deploy --context env=test
