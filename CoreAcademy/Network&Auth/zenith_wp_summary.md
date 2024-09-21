## Zenith Whitepaper:

### Abstract:

 - We have 4 Goals:
    1) Create the foundation for the Urbit Native Economy
    2) Provide a clear narrative for why address space is valuable.
    3) Create an urbit asset that is more easily accessible to a broader audience.
    4) Create the currency that incentivizes behaviours that support network adoption and growth.


### Introduction:

- Urbit consists of Azimuth (PKI and Ethereum Infrastructure L1/L2) and Arvo (A functional OS) based on Nock, housed in Vere VM.

#### General Problems with Azimuth:

- Gas wars caused a L2 Optimism Rollup patch, which was implemented to reduce gas fees ($100 -> $10). This was seen as crippling network adoption at the time.
- There are a number of drawbacks to this:
    - L2 assets can't roll back to the L1 chain.
    - A number of L1 features cant be done on L2 assets that have migrated forward.
    - Offchain records for ownership, other operations are not easily seen by users (or Etherscan).
        - Read: No backing Virtual Machine for L2, so all our old Smart contracts cant work with it.

#### Problems with Urbit:

- No mechanism for global state, or decentralization search.
    -  "...we can reach there sponsor, but not them.."
    -  "I've been trying to reach group X for a month now".
- No Primitives for market activity.
    - Just local watering holes, groups and word of mouth. Like bartering in the 1700s.
- We don't want a centralized repo of all our links to content, as that is anti-urbit.
- Because of urbits frozen, soverign philosophy, its nearly impossible for anyone to make money (~wispem-wantex)
- Vaporware tried to solve this, using the idea of NFTs as software, but that died...
- Solution: Blockchains as our global store.

### Ecosystem:

- In addition to the Urbit Foundation, there will be the Azimuth Foundation. 
- UF, AF, Tlon, and Eternal Golden Braid.
- Stars and Galaxies will have a pivotal role in maintaining the global store, recording transactions, etc.  They will perform MEV at two levels, to incentivize them to run the transactions network and economy (more on this later...)

### The Roles of Address Space: 

- Galaxies and Stars work together to implement a PoS/PoC for the Zenith Blockchain.
- Stars are **block builders** - they bundle planet transactions and day-to-day transactions together, and submit them to Galaxies.
- Galaxies are block validators, and select different bundles, to Maximize MEV.
- Galaxies must share some MEV profit with stars, who assist them.
- Blocks will have a Maximum Size.
- Galaxies that stake more $U have more opportunities to act as validators (higher chance). Stars must stake $U into galaxies, to have their own stake.  
    - Obviously, fraudulent or corrupted batches should be punishable by Galaxies.
- transactions on urbit are simple.
    - every point (except comets and moons) has a PKI, and signs messages using its private key. 
    - This private key also derives wallet seeds, as well as other addresses.
    - we can use infrastructure already to make blockchain transactions using Arvo functionality.
    - The only thing missing is the $U token.

### The $U Token:

- the native fee token of Zenith.
- Peg: 1 planet is $1U.
- Network growth: Galaxies make stars, and stars make planets. Planets do day to day transactions and interactions between users on the network. This is where the economy stems from.
    - Example:  Planet X sells NFTS, Planet Y publishes a paywalled article, Star Z spawns 5 planets for sale...etc.

### Sources of $U, and Tokenomics:

- lockdropped Stars and Galaxies recieve a drop of $U form the TGE (Token Genesis Event).
- $U is released overtime (vested), and passed between different points for transactions, like money.
- Galaxy minimum Stake: $U 131072
    -  any funny business (stars and galaxies), and their stakes get slashed.
- Total Supply: 2^32 (same number of planets and superior points).
- Block Reward Emissions (?)  32 years, with 4 halfings.
- For TGE (Token Genesis Event): 64% of total supply will be pre-mined and distributed to stars, galaxies, UF, AF and other holders.

#### Formulae for Tokens Distribution:

- Each Star (who participates in the 5 year vest) will recieve:

$$ FTA = \tfrac{952451948}{[Star L.D Participation Rate][Total Urbit Stars]}$$

- Stars that do not do the full 5 years will be award according to:

$$ Awarded = [FTA](1 - (5 - [Lock Period Yrs][0.20])) $$

- Each Galaxy will Recieve:

$$FTA =  \tfrac{9620727}{[Galaxy L.D P Rate][Total Urbit Galaxies]}  $$

- There will be a token bonus pool, that is filled as network transactions go on. This helps to fund things later on in the lifecycle of the project.  There is a bonus pool for both stars and galaxies.  For stars, the formula is:

$$BP = [Star LD Part Rate]*[FTA] \sum_{j=1}^{4} ([Stars locked for (5-j) years]*[0.2*j]) $$

- There is an additional bonus for those with low time preference (5 year lockup). Any unclamed tokens at the end, are distributed to these participants, as a further bonus.

### Roadmap and Implementation:

- Zenith will start as a Ethereum L2 stack with its own EVM chain. 
- Assets can be transferred between L1 and L2 will be a basic feature.
- New Zenith Contracts deployed to offchain EVM, are approved by Senate of Galaxies.
- Cosmos SDK is proposed, as it is highly modular. And we can swap in some urbit modules (from Arvo), that already exist.
- **End Goal (many years):** No more Ethereum Crap.  Our own Blockchain, copied from the Ethereum History, all running on a Separate Urbit blockchain, tightly linked with Arvo OS.
- Eventually, everything will be L1 UrbitChain. But many years away...
- PKI still lives in Jael, and is intermeshed with Ames.  We don't use the blockchain for this.
- 


#### Other Problems with Urbit (My own thoughts and readings):

- Heavily noted liquidity issues. 
- Dead markets and arbitrage for outsider markets (UF's value of stars vs Openseas (literally: 10x difference)).
- low liquidity - just look at "The Marketplace group"
- arbitrary valuations (aesthetics and special names), that not everyone agrees with.
- Barrier to entry to spam isn't high, and nobody uses censure.sol anyways.
    - There is a starving/disenfranchized urbiter in our group of 5000, that a spammer could use to help them coordinate attacks/spam (theoretically).


### Applications on Urbit:

#### Azimuth Only Apps:

- VPN and Tailscale (decentralized VPN.)
- Passports: Attestation of Web2/3 profiles, that stems from an Urbit ID (signed by users private key). 
- Urbit ID as HD Wallet:  We can generate many PKI pairs from our Master Ticket, and this gives us keypairs for different protocols.

#### The Scry Oracle:

- Currently, the global namespace involves our ships seraching our peers group, or asking a galaxy where things are.  This leads to a lot of problems in finding groups, assets, etc.
- The Propsed Scry Namespace is a URL System.
- We will encode all scries for assets as tranactions on a blockchain - the immutable ledger will give us permanent URLs that lead to hashed assets.
- Idea: Ship X looks for an asset, it gets pointed to the namespace of Ship Y.  Ship Y sends the asset, and attests its authenticity, as Ship Y can sign things with its Private Key.
- We can also set up paywalls (in $U) for assets.
- It is important that scry paths are canonicalized:  that they are signed by the intended ship, not some other ship impersonating.
- The Scry Oracle will be implemented as a Contract in Zenith.

##### Use Cases of Scry Orcle:

- Content Distribution and Monetization: Verify ownership and distribution. Set up paywalls.
- Data Consistency:  If one owner signs, we can verify that each DL'er gets the same copy, via hashing and signing.
- Code Signing: Devleopers can sign there OTA code updates, and ensure code integrity for users.
- Proof of Authenticity: Credentials and Certifications can publish bindings at the time of issue. We verify the hash without exposing the data.


### Urbit Economy:

- we want to avoid the Attract/Extract cycle.
    - Read: Freemium overpromised/underpriced business models online, which lead to data lock-in, and high fees for profit extraction later on.
- Hosting:  We already have Red Horizon and Tlon. Users can pay with $U now, instead of a CC or ETH.
- Encrypted Backups: Store copies of your ship on hosting providers.
- Scry namespace CDNs: Pay stars in $U to store heavily used content in caches, and have high uptime.
- Buying Software: 
    - Devleopment as a Service.
    - App customization or Extension as a Service.
    - What Vaporwave was doing (make a derivative, pay owner a royalty fee).
- Pay to DM (High Profile Users)
- Private Channels (for Subscribers).
- Planet Dispenser:  This is a Zenith Contract, star planets paid for in $U in an AMM.

### Outstanding Questions:

- Will the Zenith L2 Layer correct for the "Naive Rollup" issues, and allow old L2 planets to migrate back, or at least to the new L2 chain?

- How are transactions by galaxies batched? Do they hand it over to stars...who hand them back a batch with their own transactions back to them.  Must another galaxy approve a galaxies transactions?

- For owners with multiple stars, it seems like a prudent move would be to deposit some stars in LockDrop, and keep some back for later.

- What options are there for star owners that don't participate in the LockDrop? Are they kept out of the new economy? Will the Old Azimuth contracts be kept alive, or sunsetted as Zenith matures?

- For the Distribution of $U, there is an extreme difference in allocation between AF and UF (18% vs 1%). We also see this with the proposed transaction tax (4% vs 1%, respectively)  What was the reasoning for this? 


###  Second Wartime Address:

- Tlon Runs product experience. 
- UF pushes for Arvo + Azimuth
- Zorp - Nockchain
    - relationship:  zkPoW which uses Nock.
    - Nock is a picolisp that allows us to diagonalize a alg -> number
- Lots of people moving around (Tlon, Zorp, RH, etc...)
- Groundwire -> port urbit PKI to bitcoin ordinals and chain.
    - making comets rekeyable.
    - very equalizing (nearly infinite comets).
- note: Vaporwave was not mentioned!
- This ecosystem is complicated.
- promoting urbit as a society.
    - decentralized computing and identity.
- Competition (Urbit decentralized name space (users))
    - Farcaster. and ENS
        - Farcaster is basedon Twitter, with an ENS decentralized names.
    -  you can try to call an ETH address, but it only has a 1% change that the app is installed. Not an issue.
-  our problem:
    - as we scale to larger levels, our decentralizeation will rear different core problems.  From connecting in time, to dealing with spam, to dealing with the block chian, to system wide upgrades...Each 10x will be a challenge and require technical challenges to be solved.
    - captive app, or captive identity
- difficult:  a decentralized system that behaves (performs) like a normal web 2.0 system.

- 2nd area:  contracts and blockchain stuff.
- 3rd Area:  

- 3 Directions for TL user interfaces
    - Landscape, Bridge, and Sky (shurbbery namespace browser).

- economics of operating a star.
    - its hard.
    - you can't value it outside of its planets, and what it hosts/sponsors.

- Urbit Tailscale infrastructure.
    - there is an urbit company building code for tailscale, using the urbit namespace and stack.
-  subassembly.
    - talk about goernnance.
    - 