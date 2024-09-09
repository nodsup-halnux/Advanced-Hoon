# Understanding Ames, Jael and Azimuth:

The purpose of this repo is to understandhow urbit identities, authentication and networking works across the decentralized network of ships.  By far, Ames is the most complex of the three vanes.

##  Pre-Reqs:: Internet Protocol Knowledge:

### UDP - Unified Datagram Protocol:
- A simple way to send packets of data from one point to another, where speed trumps the occasional loss of a packet.
- No handshake.
- No error correction, but has a checksum for destination error checking.
- user programmer can implement reliability mechanisms on top/external to UDP
    - such as ECCs, or packet numbering (for large bit blob reassembly).
- no guarentee that all packets will arrive, or in the correct order.
    - but you can just code/manage this yourself..
- very fast and simple to implement.
- default port: 17
- range of packet data field size: 8-65527 bytes of data
- size of header: 8 bytes.
- (!!) UDP header *does not* include IP source/destination! This wraps around the UDP packet (header + data)
    - IP is a separate protocol handled by other portions of a network stack.
    - with IP header (20 bytes), max datagram payload is only 65507 bytes.
- The UDP header: Each field is two bytes.
- The ipv4 packet with a UDP datagram inside, is shown below (for reference)[X]:

| **Field**                         | **Size (bits)** | **Description**                                             |
|-----------------------------------|-----------------|-------------------------------------------------------------|
| **IPv4 Header**                   |                 |                                                             |
| - Version                         | 4               | IP version (always 4 for IPv4)                              |
| - IHL (Internet Header Length)    | 4               | Length of the header in 32-bit words                        |
| - DSCP (Differentiated Services)  | 6               | Type of service (QoS parameters)                            |
| - ECN (Explicit Congestion Notification) | 2         | Congestion notification                                     |
| - Total Length                    | 16              | Total length of the packet including header and data        |
| - Identification                  | 16              | Unique identifier for fragmented packets                    |
| - Flags                           | 3               | Control flags (e.g., DF, MF)                                |
| - Fragment Offset                 | 13              | Position of the fragment                                    |
| - Time to Live (TTL)              | 8               | Maximum number of hops                                      |
| - Protocol                        | 8               | Protocol of the encapsulated data (17 for UDP)              |
| - Header Checksum                 | 16              | Checksum of the header                                      |
| - Source IP Address               | 32              | Source IP address                                           |
| - Destination IP Address          | 32              | Destination IP address                                      |
| - Options (if IHL > 5)            | Variable        | Optional additional header fields                           |
| **UDP Datagram**                  |                 |                                                             |
| **---UDP Header---**              | **Size (bits)** | **Description**                                             |
| - Source Port                     | 16              | Source port number                                          |
| - Destination Port                | 16              | Destination port number                                     |
| - Length                          | 16              | Length of the UDP datagram (header + data)                  |
| - Checksum                        | 16              | Checksum for error-checking of the header and data          |
| **---UDP Data---**                | **Size (bits)** | **Description**                                             |
| - Data                            | Variable        | Application data (payload)                                  |

### Understanding New Reno: TCP Traffic Management.
- The Ames vane, with its message-pump and splitting of encrypted messages into various 1kb packets, decides which packets to send/resend over the network. It must keep track of every packet it sends, and recieve and ack to ensure data transmission.
- Ames uses (New Reno), a common TCP algorithm for doing this.
- **Mini-glossary:**
    - **RTT**: Round Trip Time: Time to send + time to get an ACK.  This is also used as a timer for each packet (estimated). When it is exceeded, we worry if the packet got to its destination.
    - **MSS**: an option field in TCP header, stating max amount of data per packet.
    - **AIMD**: Additive Increase/Multiplicative Decrease
    - **Link**: transmission channel between two parties.
    - **RTO**:  Retransmission Timeout
    - **CWND**: Congestion Window Size: An integer (units of packets sent)
    - **SSTHRESH**: Slow start theshold.

####  How Reno + New Reno Operates:

1) Slow Start Phase:  Start with a CWND of size 1.  Increase by one packet for each ACK recieved.  Keep increasing until SSTHRESH is hit.  If we keep increaseing upto threshold, we assume maximum capacity on the channel: the Reno algorithm is turne down.

2) If there is no ACK, we assume a loss has occured.  This is one event where we switch to the new reno congestoin algorithm.  Note that there is a timer to resend a packet.  For new Reno, we use a *Fast Retransmit*, which shortens the old Reno wait time.  This fast retransmission is an upgrade for the New Reno.

3)  If we recieve three dup ACKS for a packet, we assume it has been lost. and attempt to fast transmit.

- Other Notes:
    - Slow-start performs poorly in less-reliable networks (such as wireless), or in older browsers where many short lived connections are created by default.
    - For ames, our sequence numbers only reset when a ship breaches.
    - No point sending a bunch of packets fast (how do we know the channel is reliable?)


## Ames:
### General Notes:
- An Ames address is a pair of (identity, @p string, public key).
- Ultimately is responsible for sending and recieving messages of any length.
- Packet transmission is done over UDP
    - So our identity triplet defaults to an IP address, which is used in the UDP packet.
    - Note:  IP addr to @p mapping is ultimately handled outside Ames, in Arvo.  You can see galaxy IP addresses in your boot sequence for your ship.
- Arvo perspective:  extend %moves across multiple Arvo instances. Vanes inside Arvo talk to other external vanes using %pleas
- Ames Guarentees:
    1) Messages within a flow processed in order.
    2) messages are delivered only once.  The reciever will always give an %ack to let us know.
- Practically, this all works because we can extend UDP and do our own ECC and packet order management.  It doesn't matter that UDP is a simplistic protocol, just send another datagram!
- Ames gets public keys from Jael, which gets them from the %azimuth

### How Ames Works:
- Ames is a vane nested inside Arvo, which the urbit OS. Arvo is run in the urbit binary, which itself runs inside Vere.
- Vere is the interface between urbit and your OS.  It is written in C.  It allows urbit to work with the external world.
- When Ames sends a packet to another Ames instance on an external machine, what is is really doing is:
    -  Forming a vane specific packet, and dispatching it to Arvo.
    -  Arvo packages this packet as a kind of move. These moves are stored in a duct.
    -  Arvo makes a system call, via Vere, to use your computers TCP/IP/Network stack, and your Ames packet is passed on the 
    hardware layer.
    - All of the above is reversed, so your recipient Ames instance can read the packet.

- Ames will figure out how to split up large pieces of data, and send them as packets.  This is called `++jamming`. Reassembly is `++cueing`
-  All sent packets are encrypted with AES-256.
- For an Ames Packet, the following protocol is outlined for a Header and Body:

#### Header (32 Bits):
[0]:  Relay Flag
[1-20]:  Checksum
[21-22]:  Reciver Address size
[23-24]:  Sender Address size
[25-27]:  Ames protocol version
[28]:  Ames or Fine Bit?
[29-31]:  Reserved Bits.

- The Address size refers to whether our target is a galaxy or star. (11 or 10)
- Items can be relayed through other nodes, and not all messaging is direct.

#### Body:

4 Bits:  Sender life
4 Bits:  Reciever life
Var:  Sender address
Var:  receiver address
48 Bits:  Origin (if relayed)
128 Bits: SIV for AES-256
16 Bits:  ciphertext size
Var:  ciphertext payload itself.

- Note that the life number refers to the current number of key owners for an @p urbit point.
- Reciever address is often longer than the sender address.
-  ++jamming is really the process of creating a ciphertext from a noun.
    - Ames will cut up the ciphertext into 1kB or smaller packets, to be dispatched.
- The receiving Ames will cue up the ciphertexts (reassembled), and then they are decoded and turned into the original noun.
-  Address size is determined by the header.  If the relay bit is set, 32 bits of the origin are the IP address, and the rest are the port number.

### Protocol (Sending) Operation:

- Ames will periodically send a packet over and over, until it gets a response.
- Ames has acks and nacks.
    -  An ack is sent to acknowledge the receipt of a packet.
    - A nack is sent when a packet was recieved, but some error occured.
- If a nack has occured, ames can block waiting for the *naxplanation*.
-  IP stack and addressing is handled by the users OS and the run-time (vere). IP addresses are opaque to Ames, and generally left alone.


### Messages and Flows:
- Naturally, Ames must manage a message.  Messages are usually > 1kb, so we must maintain a record of all of our split messages, the acks we recieve, lost packets, etc.

- We have a `message-pump`, and structures to store .unsent-messages, acked messages, and a congestion control algorithm to attune parameters, and monitor the whole affair of transmitting all our data.

- There are two levels of pump: `|message-pump` and `|packet-pump`. Message pump sends tasks to packet-pump (likely master-slave configuration).

- various timers trigger re-sends of packets, or adjust our congestion parameters as our events go on.

- a `bone` is a duct handle, our duct being a queue of messages we wish to send.  The `ossuary` maps our bone integer, to a particular duct storing our message.

- Our Pump Metrics, which are a custom New Reno implementation, are as follows:
```
+$  pump-metrics-16
  $+  pump-metrics-16
  $:  rto=_~s1
      rtt=_~s1
      rttvar=_~s1
      ssthresh=_10.000
      cwnd=_1
      num-live=@ud
      counter=@ud
  ==
```

### What is Fine? 

- it involves remote scrying - or the read only exposure of a vane/ships namespace.
- there is no separate fine vane.  It is implemented between `ames.hoon` and `/vere/io/ames.c`
- remote scries handled by the runtime. Local Ames scries handled by Ames itself.


### Practical Work and Exercises.

#### Running scries for Ames:

`.^((map ship ?(%alien %known)) %ax /=//=/peers)`

Gives us a list of all known and alien ships, in the `peers` map in our `ames-state` structure

```
=filtergate  |= r=[p=@p q=@tas]  ?:  =(q.r %alien)  %.y  %.n
(skim ~(tap by .^(((map ship ?(%alien %known)) %ax /=//=/peers)) filtergate)
```

Gets a list of all aliens (a significantly smaller list)

`.^(ship-state:ames %ax /=//=/peers/~nodsup)`

Get the ship state for a particular entry, in the giant list above.

`!< message-pump-state:ames .^(vase %ax /=//=/snd-bones/~zod/0)`

Inspect the message pump.  Curiously, it is a vase.


1)  Examine ++split-message to see how messages are broken up into pieces.  What calls split-message, and what does it call?

```
::  We maintain an index, we don't create 1kb nouns that sit around in our subject tree.
::  met computes the number of a blocks in b.  So we can pull 1kB of data out of our message.
:: num-fragments was precomputed before, and is a bound.
:: We just keep calling split message, and keep updating the counter.
::  split message itself is called by feed-packets:mu helper core!
++  split-message
  ~/  %split-message

  |=  [=message-num =message-blob]
  ^-  (list static-fragment)
  ::
  =/  num-fragments=fragment-num  (met packet-size message-blob)
  =|  counter=@
  ::
  |-  ^-  (list static-fragment)
  ?:  (gte counter num-fragments)
    ~
  ::
  :-  [message-num num-fragments counter `@`message-blob]
  $(counter +(counter))
```

2)  Examine `++hear`:

-  This is a more complicated gate.
- recieves message fragment, may or may not complete message. Many cases.
- gate checks and cares about the following things:
    - do we have last fragment?
    - do we have a dup?
    - only consider upto 10 messages in the future.
    - if we have the whole message,
    assemble and send to vane.
- note the var `sink`  this is where the messages are sunk and assembled, to complete a full message.

3)  Examine `++assemble-fragments`:
- its quite simple.
- the returned type is a noun (*)
- we have a fragments map, and we feed a list (called sorted) into ++cue

### Ames: Structures and Connected Files:

####  lull.hoon:

- lull.hoon is located in the %base desk, in /sys/lull.hoon.  It contains structures for Arvo, which manages all of the working vanes, and implements Urbit's "operating function".
- In lull.hoon,  ames interface structures are listed. They are as follows:
-  we have a top level definition for `++  ames`  which is a **lead core** (bivariant).  This means the reads and the writes for ames, for any other core handling an instance of this, are opaque.
- Note that this $ames structure is an **interface definition**.  Likely used for mold validation for the vane.
- Ames functional work can be split into tasks (jobs) and gifts (events and side-effects).
- **Some $tasks of note:**
    - [%hear =lane =blob]: a packet from unix
    - [%dear =ship =lane]: a lane from unix (a lane is a ?(@pC @uxaddress)) - an opaque kind of address.
    - [%heed =ship]: track peer's responsiveness.
    - $>(%plea vane-task): request to send a message.

- **Some $gifts of note:**
    - [%boon payload=*]:  response message from external ship.
    - [%send =lane =blob]: packet to unix
    - [%nail =ship lanes=(list lane)]: lanes to unix
    - [%turf turfs=(list turf)]: domain report, from jael
    - [%saxo sponsors=(list ship)]:  our sponsor list report

- We also have a structural definition, to store our peer-state.  There are thousands of peers on the network, so this gets to be quite large!
- Peer State (some fields of note):
    - peer-state: a complex cell of the following:
        - symmetric-key
        - life and rift
        - public-key
        - sponsor=@p
    - route: (unit [direct=? =lane])
    - ossuary: bone (int) to duct map.
    - snd=(map bone message-pump-state)
    - rcv=(map bone message-sink-state)
- what is a duct? A duct is an queue of messages that we process.
- What is a bone? It is a message flow index.  It is incremented by 4 everytime.
    - bones are interpreted at the bit level.
    - LSB is 0, means we are sending. If 1, we are recieving.
    - next bit inidciates if we have a normal flow or naxplanation.
    - Note: 4 = 100 in binary.
    - So we can interpret our bone as bone % 4, and the left over bits are an interpretation.
- (!!) The symmetric key for each peer is not encrypted! You can use a scry to look at a particular one.  Any user that hacks into your console can find this key, and eavesdrop. 


#### Ames.hoon:
- Location:  ~/ship/base/sys/ames.hoon

- doesn't need to import lull.hoon and zuse.hoon, as this is core functionality in the %base desk.

- Ames has its own internal state `+$  ames-state`, a cell of the following:
    - peers:  (map ship ship-state)
    - unix: a duct reference
    - life:  how many times our ship has rekeyed
    - rift: number of breaches?
    - crypto-core: handle for crypto tools core
    - bug: debug level
    - snub: a cell that allows us to white/black list ships
    - cong: congestion

- Note:  There are a number of legacy structures that reference themselves in sequence - this represents incremental changes over time.  Always choose the structure with the highest index.

- Ames has 5 major calls, and 5 helper cores to help it get the job done>
    - Calls:
        -  ++ call:  handle request stack
        -  ++ take:  handle response $sign
        -  ++ stay:  extract state before reload
        -  ++ load:  load in old state after reload
        -  ++ scry:  dereference namespace
    - Helper Cores:
        - ev:  event handling core
        - mi: message recieve core
        - mu: message send core
        - pe: per-peer processing core
        - pu:  packet pump.

- Large parts of the Ames code file are about generating an "Adult Ames".  Ames is constructed from many different components, and then assembled into a fully functioning vane.  This occurs during the binary metamorphasis when you first boot your ship.
- We have larval core basic implementations, and we assemble them into the adult core.
- The external vane interface is structured as follows:

```
|=  our=ship
::  larval ames, before %born sets .unix-duct; wraps adult ames core
::
=<  =*  adult-gate  .
    =|  queued-events=(qeu queued-event)
    =|  $=  cached-state
        %-  unit
        $%  [%5 ames-state-5]
                ...
            [%20 ^ames-state]
        ==
    ::
    |=  [now=@da eny=@ rof=roof]
    =*  larval-gate  .
    =*  adult-core   (adult-gate +<)
    =<  |%
        ++  call  ^call
        ++  load  ^load
        ++  scry  ^scry
        ++  stay  ^stay
        ++  take  ^take
        --
    |%
    ++  larval-core  .
    ::  +call: handle request $task
        ++  call
        ++  take ..
    --
```


##### Looking at Each Call:

1) **Call: handle our request stack.**
- in the larval arm,  we do the following:
    - check if unix-duct is sig, check if queued-events is sig.
        - %.y:  move around legs and recompute wiht =^. We ignore tasks as we are sitll loading in this state.
        - %.n: Start scanning our -.task for different tags (%born, hear)
            - in MM, we make a cell of [moves larval-gate]
            - For hear, we just return unit larval-gate

- For the adult arm, we have an event-core door that we prime with data.
- Here, we handle the full set of tasks.
- each task has a corresponding on-task:event-core arm.  All of the processing is delegated here.

2) **Take:  handle response signs.**
- For the larval arm:
    - we again check if unix duct is ~.  This indicates Metamorphasis, most likely.
    - behn is used as a drainage timer, for the event-queue.
    - there is no separate queue for events, it looks the same as ++call

- For the adult arm:
    - event core also handles takes.
    - we have a restricted set of sign responses. Mainly just **ames, behn gall and jael**. 

3) **Stay: extract state before we reload.** 
- Just a versioned cell with the following: `[%20 %larva queued-events ames-state.adult-gate]`

4) **Load: loads in old state after reload.**
- In the building (metamorphasis phase), load constructes a structured mold, that references one of the many legacy states.  One particular example is below:

```
$:  %5
$%  $:  %larva
        events=(qeu queued-event)
        state=ames-state-5
    ==
    [%adult state=ames-state-5]
==  ==
```

- So an adult ames is an adult state, coupled with a larval events queue, and a redundant ames-state structure (odd).

- for the adult arm, we call the ames-gate and load the ames-state into it with `ames-gate(ames-state +.old-state)`
- The alias for ames-gate is just hte subject (.)

5) **Scry: namespace lookup**
- Curiously, the MM ++scry just references scry:adult-core.
- we can't scry during MM (I guess).

#####  Looking at each Helper Core:

1) ev (Event Handling):
- Before defintion, there is jet registration with `~%  %per-event  ..trace  ~`
- This is the largest of the cores (> 1000 lines), handling both task and response events.
- Some things of note:
    - lots of helper functions peppered throughout (get-peer-state, get-sponsors, etc...)
    - acks and nacks sent from this core (send-ack, send-nack).
    - on-<task> is the corresponding arm that processes a task.
    - on-hear, the messaging task, has a lot of helper arms and different cases to consider.
    


2) mi (Message Recieve):

3) mu (Message Send):

4) pe (Per-Peer Processing):

5) pu (Packet Pump)




#### Vere I/O Driver: ames.c
- Location: This runs in the vere runtime binary, at ~ship-pier/.bin/live/vere. It's code can be found on the github repo, at  [vere/io/ames.c](https://github.com/urbit/vere/blob/develop/pkg/vere/io/ames.c) 




## Jael + Azimuth:

### Pre-requisite Knowledge:

#### ERC-721 Notes[X]:

- **ERC-721** is a popular Ethereum token standard used for creating **non-fungible tokens (NFTs)**.
- ERC-721 defines several mandatory functions that contracts must implement. These functions ensure interoperability between different platforms and wallets. Below are the key functions:

1. **`balanceOf(address owner) -> uint256`**:
   - Returns the number of NFTs owned by the given address.

2. **`ownerOf(uint256 tokenId) -> address`**:
   - Returns the owner of the specified NFT (identified by `tokenId`).

3. **`safeTransferFrom(address from, address to, uint256 tokenId) -> bool`**:
   - Safely transfers ownership of an NFT from one address to another. This ensures that the recipient can actually handle the NFT (i.e., it checks if the recipient is a smart contract that supports ERC-721).

4. **`transferFrom(address from, address to, uint256 tokenId) -> bool`**:
   - Transfers ownership of an NFT from one address to another without checking if the recipient can handle ERC-721 tokens. This is a lower-level transfer function.

5. **`approve(address to, uint256 tokenId)`**:
   - Grants or revokes permission to `to` to transfer the specified NFT on behalf of the caller.

6. **`getApproved(uint256 tokenId) -> address`**:
   - Returns the address currently approved to transfer the specified NFT.

7. **`setApprovalForAll(address operator, bool approved)`**:
   - Approves or revokes permission for another address to manage all of the caller’s NFTs.

8. **`isApprovedForAll(address owner, address operator) -> bool`**:
   - Checks if an operator is allowed to manage all of the assets of the `owner`.

9. **`safeTransferFrom(address from, address to, uint256 tokenId, bytes data) -> bool`**:
   - Safely transfers ownership with additional data (used for optional parameters or additional checks).

- Additionally, ERC-721 requires the following events to be emitted:

1. **`Transfer(address indexed from, address indexed to, uint256 indexed tokenId)`**:
   - Emitted when ownership of any NFT changes by any mechanism.

2. **`Approval(address indexed owner, address indexed approved, uint256 indexed tokenId)`**:
   - Emitted when the approved address for an NFT is changed or reaffirmed.

3. **`ApprovalForAll(address indexed owner, address indexed operator, bool approved)`**:
   - Emitted when an operator is enabled or disabled for an owner.

- **Strengths of ERC-721:**
    - **Ownership and Provenance**: ERC-721 enables clear and transparent ownership records on the blockchain, which is critical for digital assets with value.
    - **Extensibility**:  The standard can be extended with additional functionality, such as metadata or complex transfer logic.
-  **Weaknesses of ERC-721:**
    - **Scalability**: Managing large numbers of NFTs can be resource-intensive, leading to higher gas costs on Ethereum.
    - ERC-721 may not be the best choice for use cases requiring fungibility or mass token issuance (e.g., loyalty points or stablecoins).

#### Layer 2 Urbit Points:

<TDB>


- Jael is a formal vane. Azimuth refers to the collection of smart contracts on the Ethereum blockchain, that facilitates urbit identities and acts as a source of truth for ownership.

- An urbit ID, in addition to being an @p with a sponsor, uses public-key cryptography to verify its identity, and generate an AES-256 symmetric key for two ships to send messages to one another.

- Number of Points:
    - Galaxies: $2^{8}$, Stars: $2^{16}$, Planets: $2^{32}$, Moons: $\approx 2^{64} - 2^{32}$, Comets: $\approx 2^{128} - 2^{64}$.  
    - moons and comets are not even powers of two because of "superior points"[?]
    - Basically, our entire address space is $2^{128}$ points, and each point class is listed in order of most important to least important. So Galaxies are the first 256 points, and the last half of the address space is all Comets.

- Old class system:  Czar, King, Duke, Earl, Pawn.

- Key Storage Per Point Object:
    - Galaxies have their Azimuth PKI loaded on a ship boot.  This is provided by the Urbit Foundation.
    - Stars and Planets:  Have there Azimuth PKI data stored in Ethereum, Jael fetches it from Ethereum and stores it locally.  This data is renewed on breach.
    - Moons:  Azimuth PKI data is stored locally in their planet's Jael database.  Planet has full control over their private key.
    - Comets have no Azimuth PKI data - life and rift is always zero. No azimuth data available.  They apparently "self-attest", and are recognized by all higher rank points on the network.  There life and raft number are both zero.


### Azimuth and Ecleptic:

- The actual Azimuth state is stored on the Ethereum Block chain.  A series of connected smart contacts work to implement it state and functionality.
- The repo is [here](https://github.com/urbit/azimuth/tree/master)

#### Summary of Azimuth Components:

- **Azimuth.eth:**  This smart contract contains all of the Azimuth data structures, for storing urbit's point's state on the block chain. 
    - READS:
        - Lots of arrays and other data strutures.
        - lots of getFunctionality.
    - WRITES:
        - lots of setFunctionality including:
            - spawn proxy, management, owner, and keys.
- **Ecleptic.eth:**  This smart contract contains all of the business logic for performing operations on the state (mutation).  Urbit Bridge mainly interacts with this!
    - NFT (ERC-721) code and functionality is implemented in this contract.
    - Despite claims of separation logic, lots of writes are straddld across in Azimuth.eth
    - READS:
        - not many. Go read from Azimuth itself.
    - WRITES:
        - we see lots of state change functions here (spawn, set voting, set transfer, cancelEscape, etc).
        - this is an interface in front of private Azimuth.eth functions that directly manipulate the state.
-  **EclepticBase.eth:**  This allows for upgrade functionality for the Ecleptic contract. An approved proposal would use this to perform an upgrade.
- **EclepticResolver.sol:**  Support code to resolve Ethereum Name Service addresses (like yourname.xyz or theirname.crypto). DNS over Ethereum.
- **Censures.eth::**  Rudimentary contract for negative reputation management. Stars can reprimand bad actors by casting negative votes for planets and other points, who misbehave.
    - READS:  all the data structures involved in implementing its purpose.
    - WRITES:  censure and forgive().  Very basic.
- **Claims.eth:**  Make upto 16 claims per urbit point. These are just notes, or bytes of data that can be attached to a point on chain.  This functionality was never used.
-  **Poll.eth:**  Used for polls by the galactic senate. combines both state and business logic.  (Not my concern - only for galaxy owners).

- There are many other contracts, for SafeMath, for Linear and Conditional Star release, etc.  We are mainly concerned with azimuth points and PKI, so these are left alone for now.

## Understanding Bridge:

Bridge is a TypeScript Front end, connected to a python backend, that interacts with Azimuth.  It gives a WebUI interface for Stars and Planet owners to perform Azimuth operations.  


### What is a Breach?

- A breach occurs when a ships event log becomes corrupted, or when it chooses to factory reset itself.  This means it cannot attest to its current identity online, and so when a breach is formally signalled, the network "forgets" the old ship, and treats it like a new startup.
- Continutiy: how ships remember the order of their own network messages, and the network messages of others.  This is stored in their own personal event log.
- The factory reset is not an individual action.  The network decides to treat a ship like it is brand new - and forgets its previous history.
    - practically, everyones Ames peer-state entries and Jael keys for the ship, are erased and reset!
- Transferring an azimuth point to another ETH address also initiates a factory reset.
- Breach = factory-reset.  Don't get confused by the archaic terminology.
- Note that a breach is performed on Bridge, not on the Dojo. So a ship actually does not know about its own breach!  When it is at its weakest, the network will come for it when it least expects it.


#### Notes on /sys/vane/ames:++on-publ-breach

- 

### Questions and Exercises:

1) Execute the read function on Etherscan.
    - Done for Censure, Azimuth, and a few other contracts.
    - Click on the Contract Tab -> READ, and interact with the contract live.
    - **Note:** Reads on the Ethereum network are free, only WRITES require gas. So
    a .js library can just query an ETH node, and pull the data you want.

2) 

Q) If Comets have no Azimuth PKI entry, how do they work? DO they just relay through the UF list of known galaxies after Metamorphasis?

Q)  For Moons and Comets, they are not even powers of two because of the "superior points".  What are they?

Q)  In the boot sequence (during MM), how do we map galaxy names to ip addresses? Walk through the call sequence. Are the eth-*.hoon libraries used?

Q) Does the urbit binary, or anything in the %base desk consider Censures.sol? Or is it just a wanted posting online for bad actors? Does anyone check.


## Understandng Jael

- Jael is the arvo vane that queries Azimuth.  It does not do this directly, but uses the %azimuth agent and eth-watcher files to run a thread to query the block chain, and return urbit ID data for various requests.

### /sys/lull interface defintions:

- Jael has Tasks and Gifts to fullfill different jobs, and pass messages back to different vanes and clients.
- Lots of our structures are included in a lead core (bivalent - opaque reads and writes)


- +$ gift:
    - [%boon payload=*]: An Ames response
    - [%private-keys =life vein=(map life ring)]: Ship private keys
    - %public-keys =public-keys-result]: Ethereum Changes

- +$ seed structure:
    - [who=ship lyf=life key=ring sig=(unit oath:pki)]

- +$ task
    - [%fake =ship] Boot a fake ship
    - [%meet =ship =life =pass]: Contact a breach shipped, update.
    - [%rekey =life =ring] : update private keys
    - [%resend ~]: resend private keys
    - [%ruin ships=(set ship)] : pretend breach (?)
 
- there are also a lot of group theory definitions, to do elliptic curve stuff. Interesting....
- Monoid, rings and groupoids are mentioned.


### Structure of Jael (/sys/vane/jael):
- There is one mega structure, (state-2) that contains the pki state, and the ether node state for querying:

```
+$  state-2
  $:  %2
      pki=state-pki-2                                   ::
      etn=state-eth-node                                ::  eth connection state
  ==                                                    ::
+$  state-pki-2                                         ::  urbit metadata
  $:  $=  own                                           ::  vault (vein)
        $:  yen=(set duct)                              ::  trackers
            sig=(unit oath)                             ::  for a moon
            tuf=(list turf)                             ::  domains
            fak=_|                                      ::  fake keys
            lyf=life                                    ::  version
            step=@ud                                    ::  login code step
            jaw=(map life ring)                         ::  private keys
        ==                                              ::
      $=  zim                                           ::  public
        $:  yen=(jug duct ship)                         ::  trackers
            ney=(jug ship duct)                         ::  reverse trackers
            nel=(set duct)                              ::  trackers of all
            dns=dnses                                   ::  on-chain dns state
            pos=(map ship point)                        ::  on-chain ship state
        ==                                              ::
  ==                                                    ::


```


- There are two 'engines', or two letter cores that do support work. A summary of obth are below.

- First, the `++of` engine:
    - handles "top level semantics", 
    -  At the top of the core, we pin *moz* which is a list of moves `+$ move  [p=duct q=card]`. 
    - we also store state-2 locally
    - the `++call`  arm takes a hen (event cause) amd tac (event data) as an input.  It processes our %tasks we stated before. This is one of the biggest arms in the file. There are forks for %dawn, %private-key, %listen....etc
    - The `++take` arm deals with various responses from other vanes, that Jael is waiting for. Such as Behn and Ames.

- There is also a ++feel core that handles and tracks public key updates.

-  Next, the `++su` core:
    - handles actions and subscriptions to other ships and vanes, derived state and updates external agents after actions are taken (in various situations).
    - 

#### Questions and Exercises:

Q:  What are absolute effects?
    This is likely direct effects on our pier and state. It is side-effects and state change on ourselves.

Q:  What are derived effects (of the absolute effects)
 Jael state comes in two parts (abolute and relative).  This is all of the state needed to manage subscriptions, and send information to others about changes.

1) Trace an Azimuth Update from a %fact via ++new-event to ++feel's operations.

The Trace reveals the following:
- we see the %fact @tas tag located in the `++take` arm of `++of`. The take arm deals with varioius responses to other vanes (like behn or gall)
- The fact code does the following:
```
:: Positive assertion. Is tea an atom
?>  ?=([@ *] tea)
::  Deferred expression recomputed - app is i.tea
=*  app  i.tea
::  Pin sample to head, normalize mold, calculate diff
::  of point betwen q.q.cage.p and +>.hin (lark notation)
=+  ;;(=udiffs:point q.q.cage.p.+>.hin)
::  Call, curd gate - tisgal compose inverted expressoin
::  ??
%-  curd  =<  abet
(~(new-event su hen now pki etn) udiffs)
```
- next we call ++new-event.  This is more complicated:

```
::  Gate that takes an azimuth point.
|=  =udiffs:point
::  type cast by inferred type of this-su
:: this-su is just a local subject.
^+  this-su
::  pin original-pos, set to pos.zim.pki
:: and calculate our trap below.
=/  original-pos  pos.zim.pki
:: inferred type local subject, again.
|-  ^+  this-su
::  is sig? If yes, return subject
?~  udiffs
    this-su
::  If no, get our point and the difference.
=/  a-point=point  (~(gut by pos.zim.pki) ship.i.udiffs *point)
=/  a-diff=(unit diff:point)  (udiff-to-diff:point udiff.i.udiffs a-point)
:: tiswut takes 4 args!
:: Expands to: =.  p  ?:(q r p)  s
=?  this-su  ?=(^ a-diff)
    =?    this-su
        ?&  =(our ship.i.udiffs)
            ?=(%keys -.u.a-diff)
            (~(has by jaw.own) life.to.u.a-diff)
        ==
    ::  if this about our keys, and we already know these, start using them
    :: Exchange a leg
    =.  lyf.own  life.to.u.a-diff
    ::  notify subscribers (ames) to start using our new private keys
    ::  Our keys
    (exec yen.own [%give %private-keys [lyf jaw]:own])
    ::  Not our keys...
    (public-keys:feel original-pos %diff ship.i.udiffs u.a-diff)
$(udiffs t.udiffs)
```
- First, lets examine the feel branch of =? end cases.  The `++feel` arm is a core with a ++public-keys arm, which is a gate. A lot of operations occur in this gate, so we summarize the code with explanations instead:
    - Our input is our (map ship point), and a public-keys-result, which comes about from our calculated difference, before.
    - We return a feel type with ^+
    - We first check if our public-keys result is head tagged with %full.
    - we assign point1 from points.public-keys-result, this is a cell of @p and point data.
    - next we have another =?, we conditionally change a leg of the local subject.
    - Note Ref: A Zim is the following:
```
 $=  zim
    $:  yen=(jug duct ship)
        ney=(jug ship duct)
        nel=(set duct)
        dns=dnses
        pos=(map ship point)
```
- we get our point data, and look to see if our rift number has increased for a point. if so, return a [%breach] structure, and inform all subscribers that we have on record.
- There is a case to delay resubscribe, because ames clears all messages on a breach anyways. This is done with the ++emit call.
- If we don't have a breach, deal with a full point.
- we calculate a rift increase, and possible breach detection again. This is for our ship ??
- at the end, we need to inform all of our subscribers that public keys have changed for us.

- Next we deal with the ++exec call. This is to notify our subscribers that we have a new private key. The call, and the code is as follows:

```
(exec yen.own [%give %private-keys [lyf jaw]:own])

++  exec
    :: Send a card to all ducts in the set
    |=  [yen=(set duct) cad=card]
    ::  What is noy? 
    :: Yen is a (set ducts). Tap turns the set into a list.
    =/  noy  ~(tap in yen)
    |-  ^+  this-su
    :: check if empty, expose i/t
    ?~  noy  this-su
    :: Call the duct, and load card and data and send.
    $(noy t.noy, moz [[i.noy cad] moz])
```
- **So what did we do overall? Azimuth gave us a fact after a query, we used the su engine to process the fact as an event, and checked to see if our keys/other keys changed, and then updated subscribers accordingly.**

2) Test out the following scrys:

i) `.^(@p %j /=code=/(scot %p our))`

Gets our ship's access code.

ii) `.^(@p %j /=sein=/~nodsup-labnux)`

Gets the ships sponsor (original spawner), not escaped.

iii)  .^((list @p) %j /=saxo=/~sampel-palnet)

Gets sponsorship chain in a progressive cell.

iv)  `.^([yen=(jug duct ship) ney=(jug ship duct) nel=(set duct)] %j /=subscriptions=/1)`

An example of the output for my ship is below:

```
[p=~ralbec-normel q={[i=/ames/public-keys t=[i=//ames t=~]] [i=/gall/sys/era t=[i=/dill t=~[//term/1]]]}]
        [p=~wolred-liswet q={[i=/ames/public-keys t=[i=//ames t=~]] [i=/gall/sys/era t=[i=/dill t=~[//term/1]]]}]
        [p=~nospur-sontud q={[i=/ames/public-keys t=[i=//ames t=~]] [i=/gall/sys/era t=[i=/dill t=~[//term/1]]] [i=/clay/sinks t=[i=/dill t=~[//term/1]]]}]
        [p=~lonlud-diffet q={[i=/ames/public-keys t=[i=//ames t=~]] [i=/gall/sys/era t=[i=/dill t=~[//term/1]]]}]

```

For a well broken in ship with many interactions with different points, this list is huge.

3)  Examine the %step exercise in the Jael docs:

This is a tutorial to change your webcode. it is done for ~fakezod.

Firstly, what is a %step? Step is a task (or a job for Jael to do). It resets our webcode, essentially. It has no arguments (being ~) in the tagged cell.

Run `.^(@ud %j /=step=/(scot %p our))` to see that we are on step 0 .

We pass a %step task to jael, by using the `|pass` generator. `|pass [%j %step ~]`


Q:  What does a "point" look like? Just a hex number?

Q: Why is our code only 64 bits? Isn't that low security?
 - - (!!) The symmetric key for each peer is not encrypted! You can use a scry to look at a particular one.  Any user that hacks into your console can find this key, and eavesdrop. 



#### Azimuth Data Flow:

- Jael does not talk to the ETH block chain directly, it uses Gall's %azimuth app to do so.  To query the ETH blockchain requires threads and promises - which are outside the scope of Jael. So these are compartmentalized into a Gall App.

- So data from Azimuth flows from %azimuth and the %eth-watcher apps.  


### References:

[X] https://chatgpt.com/share/095aa4c3-7ec8-48fc-b449-7238f06c7ede 