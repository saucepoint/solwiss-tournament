# Deployments on Polygon Mumbai (Testnet)

[Factory](https://mumbai.polygonscan.com/address/0x6fdd00a14ba88956fe10d0653b270a8087f93e0c#code) - used to create a `SwissTournamentManager`. Call this contract to create your own, private tournament

### Examples:

[SwissTournamentManager creation](https://mumbai.polygonscan.com/tx/0x93eed39baa5f8a1d9d709a654f32883bc1c89112a7b1a7b7fffa33cfdc5be475)

[SwissTournamentManager contract](https://mumbai.polygonscan.com/address/0xdda73234721fcdff335792cff438ca613dce86f3)

[MockGame](https://mumbai.polygonscan.com/address/0x918bb1c316f76d0189eeadd7cbcf1139508cfa3d) - Called by the SwissTournamentManager to resolve matchups. I.e. maintains game logic

[Tx: playNextMatch()](https://mumbai.polygonscan.com/txs?a=0x8b7044596500a3f654300e7eeac2b30172f14426) - match execution and tournament advancement of players. Gas consumption ranges from 70k to 170k