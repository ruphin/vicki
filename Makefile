dev:
	docker run -it --rm -v $$PWD:/app --env-file ./APISECRETS ruphin/rubydev ruby run.rb
.PHONY: dev

production:
	docker run --rm -v $$PWD:/app ruphin/rubydev echo "BUNDLED GEMS"
	docker build -t ruphin/vickibot .
	docker push ruphin/vickibot
