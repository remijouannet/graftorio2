#factoriofast/bin/x64/factorio --graphics-quality low --video-memory-usage low --load-game factoriofast/saves/_autosave2.zip --threads 4

VERSION=$$(git describe --abbrev=0 --tags)

release:
	mkdir -p pkg && \
		rm -f ./pkg/*.zip && \
		git archive --prefix=graftorio2/ -o pkg/graftorio2_$(VERSION).zip HEAD

install-darwin:
	cd ../ && zip --exclude="*.git*" --exclude="*pkg*" -r graftorio2/graftorio2_$(VERSION).zip graftorio2 && \
		mv graftorio2/graftorio2_$(VERSION).zip ~/Library/Application\ Support/factorio/mods/

install-linux:
	cd ../ && zip --exclude="*.git*" --exclude="*pkg*" -r graftorio2/graftorio2_$(VERSION).zip graftorio2 && \
		cp graftorio2/graftorio2_$(VERSION).zip ~/bin/factoriofast/mods/

clean:
	rm -rf ./data/prometheus && rm -rf ./data/grafana

docker:
	docker-compose up
