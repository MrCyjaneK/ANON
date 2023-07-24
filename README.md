# ANON


## BUILD INSTRUCTIONS

Install Flutter & tor

1. Clone ANON repo: `git -c http.proxy=socks5h://127.0.0.1:9050 clone
http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/ANON.git`

2. Change current directory to external-libs: `cd ANON/android/external-libs`

3. Clone Monero repo: `git -c http.proxy=socks5h://127.0.0.1:9050 clone
http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/monero.git`

4. Go to monero folder and update submodules: `cd monero && git submodule update
--init --force`

5. Back out and build monero libs: `cd ../ && sudo make && cd ../../`

6. Build ANON: `flutter build apk --flavor mainnet --release`

Compiled APK will be found in `ANON/build/app/outputs/apk/mainnet/release`