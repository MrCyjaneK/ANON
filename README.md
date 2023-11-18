# ANON


## BUILD INSTRUCTIONS

Install Flutter & tor

1. Clone ANON repo: `git -c http.proxy=socks5h://127.0.0.1:9050 clone
http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/ANON.git --recursive`

2. Change current directory to external-libs and build monero: `cd ANON/android/external-libs && sudo make`

3. Build ANON and NERO: `make anon nero`

Compiled APK will be found in `ANON/build/app/outputs/flutter-apk/release`