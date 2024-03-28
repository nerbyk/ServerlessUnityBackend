install_deps: 
	bundle install --without development test --path vendor/bundle

unit: 
	bundle install --with development test --path .bundle
	bundle exec ruby -Ilib:test test/main_test.rb test/fixtures ./main.rb 

default: install_deps
	