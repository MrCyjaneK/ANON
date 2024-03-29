all: anon nero

anon:
	flutter build apk --flavor anon

anonstealth:
	flutter build apk --flavor anonstealth --dart-define=libstealth_calculator=true

nero:
	flutter build apk --flavor nero

dev: devanon devnero

devanon:
	flutter build apk --verbose --no-tree-shake-icons --flavor devanon

devnero:
	flutter build apk --verbose --no-tree-shake-icons --flavor devnero

clean:
	flutter clean

.PHONY: all anon nero dev devanon devnero clean