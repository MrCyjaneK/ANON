FLAVOUR = monero

all: arm64-v8a armeabi-v7a include/wallet2_api.h VERSION

arm64-v8a: $(FLAVOUR) android64.Dockerfile
	-rm -rf arm64-v8a
	-docker container rm $(FLAVOUR)-android-arm64 -f
	docker build -f android64.Dockerfile -t $(FLAVOUR)-android-arm64 $(FLAVOUR)
	docker create -it --name $(FLAVOUR)-android-arm64 $(FLAVOUR)-android-arm64 bash
	docker cp $(FLAVOUR)-android-arm64:/opt/android/prefix/lib/. arm64-v8a/
	docker cp $(FLAVOUR)-android-arm64:/src/build/release/lib/. arm64-v8a/$(FLAVOUR)

armeabi-v7a: $(FLAVOUR) android32.Dockerfile
	-rm -rf armeabi-v7a
	-docker container rm $(FLAVOUR)-android-arm32 -f
	docker build -f android32.Dockerfile -t $(FLAVOUR)-android-arm32 $(FLAVOUR)
	docker create -it --name $(FLAVOUR)-android-arm32 $(FLAVOUR)-android-arm32 bash
	docker cp $(FLAVOUR)-android-arm32:/opt/android/prefix/lib/. armeabi-v7a
	docker cp $(FLAVOUR)-android-arm32:/src/build/release/lib/. armeabi-v7a/$(FLAVOUR)

include/wallet2_api.h: $(FLAVOUR) include $(FLAVOUR)/src/wallet/api/wallet2_api.h
	cp $(FLAVOUR)/src/wallet/api/wallet2_api.h include/wallet2_api.h

include:
	mkdir include

VERSION:
	echo MONERUJO_$(FLAVOUR) `git -C . branch | grep "^\*" | sed 's/^..//'` with $(FLAVOUR) `git -C $(FLAVOUR) branch | grep "^\*" | sed 's/^..//'` > VERSION

clean:
	-rm -rf arm64-v8a
	-rm -rf armeabi-v7a
	-rm -rf include
	-rm -f VERSION

distclean: clean
	-docker container rm $(FLAVOUR)-android-arm64 -f
	-docker container rm $(FLAVOUR)-android-arm32 -f
	-docker image rm $(FLAVOUR)-android-arm64 -f
	-docker image rm $(FLAVOUR)-android-arm32 -f

	-rm $(FLAVOUR)

$(FLAVOUR):
	$(error Please ln -s $(FLAVOUR))

.PHONY: all clean distclean
