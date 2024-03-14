GAMEPLAY_BACKEND_DIR := ../gameplay_backend
LAMBDA_JOBS_DIR := ${GAMEPLAY_BACKEND_DIR}/jobs
VENDOR_JOBS_DIR := ./vendor/gameplay_backend/jobs

package_gameplay_backend:
	cd ${GAMEPLAY_BACKEND_DIR} && bundle install --without development test --path vendor/bundle
	rm -rf ${VENDOR_JOBS_DIR} && mkdir -p ${VENDOR_JOBS_DIR}
	cp -r ${GAMEPLAY_BACKEND_DIR}/assets ./vendor/gameplay_backend
	cp -r ${LAMBDA_JOBS_DIR}/* ${VENDOR_JOBS_DIR}
	for dir in ${LAMBDA_JOBS_DIR}/*; do \
		cp ${GAMEPLAY_BACKEND_DIR}/Gemfile ${VENDOR_JOBS_DIR}/$$(basename $$dir); \
		cp -r ${GAMEPLAY_BACKEND_DIR}/lib/* ${VENDOR_JOBS_DIR}/$$(basename $$dir); \
		cp -r ${GAMEPLAY_BACKEND_DIR}/vendor ${VENDOR_JOBS_DIR}/$$(basename $$dir)/vendor; \
	done

