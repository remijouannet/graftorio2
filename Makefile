VERSION=$$(git describe --abbrev=0 --tags)

release:
	mkdir -p pkg && \
		rm ./pkg/*.zip && \
		git archive --prefix=graftorio2/ -o pkg/graftorio2_$(VERSION).zip HEAD

install-darwin:
	git archive --prefix=graftorio2/ -o graftorio2_$(VERSION).zip HEAD && \
		mv graftorio2_$(VERSION).zip ~/Library/Application\ Support/factorio/mods/

clean:
	rm -rf ./data/prometheus && rm -rf ./data/grafana

docker:
	docker-compose up
