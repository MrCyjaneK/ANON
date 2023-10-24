# ANON


## BUILD INSTRUCTIONS

Install Flutter & tor

1. Clone ANON repo: `git -c http.proxy=socks5h://127.0.0.1:9050 clone
http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/ANON.git --recursive`

2. Change current directory to external-libs: `cd ANON/android/external-libs`

3. Back out and build monero libs: `sudo make`

4. Build ANON: `flutter build apk --flavor mainnet --release`

Compiled APK will be found in `ANON/build/app/outputs/apk/mainnet/release`