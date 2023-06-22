# ANON


## BUILD INSTRUCTIONS

     - Install Flutter & torsocks
     - Connect device & enable USB Debugging
     - Clone ANON repo:

             torsocks git clone http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/ANON.git && cd ANON/android/external-libs

     - Clone Monero repo:

             torsocks git clone http://git.anonero5wmhraxqsvzq2ncgptq6gq45qoto6fnkfwughfl4gbt44swad.onion/ANONERO/monero.git && cd monero && git submodule update --init --force && cd ../ && sudo make && cd ../../

     - Install & run ANON: flutter run --flavor mainnet --release