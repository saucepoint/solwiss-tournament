# Woah there, anon! Thanks for snooping but
*repo is not ready yet; feel free to poke around though* 😘

I'm welcoming improvements and suggestions. Open up an issue or [DM me on twitter](https://twitter.com/saucepoint)

You can find the outstanding work below

---

# solwiss-tournament

Inspired by [0xMonaco](https://0xmonaco.ctf.paradigm.xyz/) & the future of chain-facilitated PvP games, I created a reference implementation for a Swiss tournament manager in Solidity

([Wikipedia](https://en.wikipedia.org/wiki/Swiss-system_tournament)) 

> The Swiss system is used for competitions in which there are too many entrants for a full round-robin (all-play-all) to be feasible

> A Swiss-system tournament is a non-eliminating tournament format that features a fixed number of rounds of competition, but considerably fewer than for a round-robin tournament; Competitors meet one-on-one in each round and are paired using a set of rules designed to ensure that each competitor plays opponents with a similar running score, but does not play the same opponent more than once. The winner is the competitor with the highest aggregate points earned in all rounds. With an even number of participants, all competitors play in each round.

> In single-elimination tournaments, the best competitor may not necessarily win, because good competitors might have a bad day or eliminate and exhaust each other if they meet in early rounds.


### Example of a Swiss tournament:

![swisstournament](imgs/csgoswiss.png)


### Additional Notes on Swiss Tournaments:

* Swiss tournaments cannot identify a single winner
    * Swiss tournaments should wittle down the contestant pool, and winners should move onto single-elimination brackets
* Contestants may advance to a group where there are no other contestants. For example -- a contestant will go undefeated, and there are no other contestants that share the same win-loss record

* Outcomes of a swiss tournament can yield a set of winners which do not play nicely into brackets (2^x). For example, if there are 10 winners of a swiss tournament, some winners will need to have a "bye" in playoffs.

Please see [Example Configuration](#example-configurations) for possible outcomes of a Swiss tournament

---

*Created with [foundry](https://book.getfoundry.sh)*

## This is a **reference implementation** with stuff still being worked on:
* Factory Contract, spins up new tournaments with ease

* Flexible win/elimination thresholds (currently set to 3)

* Permissioned functions. Current functions are unprotected. Eventually only 'tournament organizers' will have permission to run matches

* Gas optimizations

* Haven't really thought of reentrancy bugs, so there's probably something out there

Proceed carefully by adding it to your own foundry repo:
```bash
forge install saucepoint/solwiss-tournament
```

---

## Cookbook

Please see [MockGameSwissTournament.sol](test/mocks//MockGameSwissTournament.sol) for additional context

```typescript
/// >> Inherit `SwissTournament`
contract MockGameSwissTournament is SwissTournament {

    constructor(uint256 _winThreshold, uint256 _eliminationThreshold)
        SwissTournament(_winThreshold, _eliminationThreshold)
    {
        // either in the constructor, or after deploy, seed the tournament with:
        // newTournament(uint256[] playerIds);
    }
    
    /// >> Implement playMatch() function body to adhere to SwissTournament
    /// >> Must decorate it with advancePlayers() modifier
    function playMatch(ResultCounter memory group, uint256 matchIndex) public override advancePlayers(group, matchIndex) {
        
        /// >> Provides information on which players (uint256s) are participating in the matchup
        Match storage matchup = matches[group.wins][group.losses][matchIndex];
        
        /// >> Implement some game logic where given 2 players, return the id of the winner
        uint256 winnerId = YOUR_GAME_LOGIC_FUNCTION(matchup.player0, matchup.player1);

        /// >> update the outcome of the match
        matchup.winnerId = winnerId;
        matchup.played = true;
    }
}
```

SwissTournament.sol handles:

1) Advancing players up and down the lattice

2) Maintains an *ordered* list of matchups

So all you need to do is call `playNextMatch()`
```typescript
// assuming we're in React
// and the tournament organizer wants to run the next match!

import { ethers } from "ethers";
import { useAccount, useProvider, useSignMessage } from "wagmi";
import abi from "../abi/YourContractOutput.json";

const CONTRACT_ADDR = "0xABCDE"
const provider = useProvider();
const contract = new ethers.Contract(CONTRACT_ADDR, abi.abi, provider);

// add contestants (via their uint256-player-ID) to the tournament
// ordered list by elo. First player (the best) matches against the last player (the worst) in the list
// these can be arbitrary playerIds as long as theyre ints and NOT ZERO
// an even amount of players is required, but is unbounded. Massive 128-contestant Swiss tournaments are possible
contract.newTournament([
    10, 20, 30, 40,
    50, 60, 70, 80,
    90, 100, 110, 120,
    130, 140, 150, 160
]);

contract.playNextMatch();
```

#### Identifying Winners

TBD

Lastly, check out [ISwissTournament](src/interfaces/ISwissTournament.sol) for view functions which provide everything that's needed for displaying the Swiss lattice on a UI.

---

## Example Configurations

Pruned Results from [SwissTournament.t.sol:testGenerateCombinations()](test/SwissTournament.t.sol)

Note: with high `win_thresholds`, it is not guaranteed that a "winner" (non-eliminated) has met the win-condition. This observation is due to contestants advancing into groups which do not have opponents to play.

```
|num_players|win_threshold|lose_threshold|num_groups|num_matches|num_winners|num_losers|
|-----------|-------------|--------------|----------|-----------|-----------|----------|
|8          |3            |3             |9         |15         |5          |3         |
|16         |3            |3             |9         |33         |8          |8         |
|16         |3            |4             |12        |38         |11         |5         |
|16         |4            |3             |12        |38         |6          |10        |
|16         |4            |4             |16        |45         |9          |7         |
|16         |5            |3             |14        |40         |5          |11        |
|16         |5            |4             |19        |48         |8          |8         |
|20         |3            |3             |9         |38         |12         |8         |
|20         |3            |4             |12        |43         |15         |5         |
|20         |4            |3             |12        |43         |10         |10        |
|20         |4            |4             |16        |50         |13         |7         |
|20         |5            |3             |14        |45         |9          |11        |
|32         |3            |3             |9         |66         |16         |16        |
|32         |3            |4             |12        |77         |21         |11        |
|32         |4            |3             |12        |77         |11         |21        |
|32         |5            |3             |15        |83         |8          |24        |
|32         |5            |4             |20        |103        |12         |20        |
|32         |6            |3             |17        |86         |6          |26        |
|32         |6            |4             |23        |109        |9          |23        |
|32         |7            |3             |18        |87         |5          |27        |
|32         |7            |4             |25        |112        |7          |25        |
|32         |8            |3             |18        |87         |5          |27        |
|40         |3            |3             |9         |81         |21         |19        |
|40         |3            |4             |12        |92         |29         |11        |
|40         |4            |3             |12        |92         |16         |24        |
|40         |4            |4             |16        |108        |24         |16        |
|40         |5            |3             |15        |98         |13         |27        |
|40         |5            |4             |20        |118        |20         |20        |
|40         |6            |3             |17        |101        |11         |29        |
|40         |6            |4             |23        |124        |17         |23        |
|40         |7            |3             |18        |102        |10         |30        |
|40         |7            |4             |25        |127        |15         |25        |
|40         |8            |4             |26        |128        |14         |26        |
|64         |3            |3             |9         |132        |32         |32        |
|64         |3            |4             |12        |154        |42         |22        |
|64         |4            |3             |12        |154        |22         |42        |
|64         |4            |4             |16        |186        |32         |32        |
|64         |5            |3             |15        |168        |15         |49        |
|64         |5            |4             |20        |208        |24         |40        |
|64         |6            |3             |18        |177        |10         |54        |
|64         |6            |4             |24        |223        |18         |46        |
|64         |7            |3             |20        |181        |7          |57        |
|64         |7            |4             |27        |231        |14         |50        |
|64         |8            |3             |21        |182        |6          |58        |
|64         |8            |4             |29        |234        |12         |52        |
|64         |9            |3             |21        |182        |6          |58        |
|64         |9            |4             |30        |235        |11         |53        |
|100        |3            |3             |9         |203        |52         |48        |
|100        |3            |4             |12        |236        |67         |33        |
|100        |4            |3             |12        |236        |37         |63        |
|100        |4            |4             |16        |284        |52         |48        |
|100        |5            |3             |15        |257        |26         |74        |
|100        |5            |4             |20        |318        |39         |61        |
|100        |6            |3             |18        |269        |19         |81        |
|100        |6            |4             |24        |340        |29         |71        |
|100        |7            |3             |20        |275        |15         |85        |
|100        |7            |4             |27        |353        |22         |78        |
|100        |8            |3             |22        |278        |13         |87        |
|100        |8            |4             |30        |360        |18         |82        |
|100        |9            |3             |23        |279        |12         |88        |
|100        |9            |4             |32        |363        |16         |84        |
|128        |3            |3             |9         |264        |64         |64        |
|128        |3            |4             |12        |308        |84         |44        |
|128        |4            |3             |12        |308        |44         |84        |
|128        |4            |4             |16        |372        |64         |64        |
|128        |5            |3             |15        |337        |29         |99        |
|128        |5            |4             |20        |418        |47         |81        |
|128        |6            |3             |18        |355        |19         |109       |
|128        |6            |4             |24        |449        |34         |94        |
|128        |7            |3             |21        |365        |13         |115       |
|128        |7            |4             |28        |468        |25         |103       |
|128        |8            |3             |23        |369        |10         |118       |
|128        |8            |4             |31        |478        |19         |109       |
|128        |9            |3             |24        |370        |9          |119       |
|128        |9            |4             |33        |482        |16         |112       |
|128        |10           |3             |24        |370        |9          |119       |
|128        |10           |4             |34        |483        |15         |113       |
|256        |3            |3             |9         |528        |128        |128       |
|256        |3            |4             |12        |616        |168        |88        |
|256        |4            |3             |12        |616        |88         |168       |
|256        |5            |3             |15        |674        |58         |198       |
|256        |5            |4             |20        |837        |93         |163       |
|256        |6            |3             |18        |711        |37         |219       |
|256        |6            |4             |24        |902        |65         |191       |
|256        |7            |3             |21        |734        |23         |233       |
|256        |7            |4             |28        |946        |44         |212       |
|256        |8            |3             |24        |748        |14         |242       |
|256        |8            |4             |32        |975        |29         |227       |
|256        |9            |3             |26        |755        |9          |247       |
|256        |9            |4             |35        |992        |19         |237       |
|256        |10           |3             |28        |759        |6          |250       |
|256        |10           |4             |38        |1002       |13         |243       |
|256        |11           |3             |29        |760        |5          |251       |
|256        |11           |4             |40        |1006       |10         |246       |
|256        |12           |4             |41        |1007       |9          |247       |
```
