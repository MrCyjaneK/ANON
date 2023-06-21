# ANON


## BUILD INSTRUCTIONS

1) Install Flutter
2) Connect device & enable USB Debugging
3) Clone ANON repo: `git clone -b view-only https://codeberg.org/r4v3r23/ANON.git && cd ANON/android/external-libs`

             git -c http.proxy=socks5h://127.0.0.1:9050 clone http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/ANON.git && cd ANON/android/external-libs

5) Back out and build libs: `cd ../ && sudo make && cd ../../`

             git -c http.proxy=socks5h://127.0.0.1:9050 clone http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/monero.git && cd monero && git submodule update --init --force && cd ../ && sudo make && cd ../../

     - Install & run ANON: flutter run --flavor mainnet --release
