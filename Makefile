all: anon nero

anon:
	flutter build apk --flavor anon

nero:
	flutter build apk --flavor nero

dev: devanon devnero

devanon:
	flutter build apk --flavor devanon

devnero:
	flutter build apk --flavor devnero

clean:
	flutter clean

.PHONY: all anon nero dev devanon devnero clean