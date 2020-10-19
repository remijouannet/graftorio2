
release:
	mkdir -p pkg && \
		rm ./pkg/*.zip && \
		git archive --prefix=graftorio2/ -o pkg/graftorio2_0.0.8.zip HEAD

install-darwin:
	git archive --prefix=graftorio2/ -o graftorio2_0.0.8.zip HEAD && \
		mv graftorio2_0.0.8.zip ~/Library/Application\ Support/factorio/mods/

clean:
	rm -rf ./data/prometheus && rm -rf ./data/grafana

docker:
	docker-compose up
