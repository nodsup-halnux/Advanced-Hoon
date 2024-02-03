:: This app uses the %squad page serving/index.hoon code, and %charlie as a Gall App template.
:: Our structure file. Standard action/update pattern is also used (in /mar)
/-  *gameuis
/+  default-agent, dbug, agentio
::Import FE file that we will serve up in ++on-poke
/=  fe-board  /app/frontend/fe-board
|%
+$  versioned-state
  $%  state-0
  ==
+$  state-0
    :: A very basic state to test Sail with.
  $:  [%0 values=(list @ud) gameboard=board playmap=playerinfo =page]
  ==
+$  card  card:agent:gall
--
%-  agent:dbug
=|  state-0
=*  state  -
^-  agent:gall
|_  =bowl:gall
+*  this     .
    default  ~(. (default-agent this %|) bowl)
++  on-init
    ^-  (quip card _this)  ::do we need the alias (io for agentio??) [!!!]
    :_  this  [(~(arvo pass:agentio /bind) %e %connect `/'gameuis' %gameuis)]~
++  on-save   !>(state)
++  on-load
  |=  old=vase
  ^-  (quip card _this)
  `this(state !<(state-0 old))
++  on-poke
  |=  [=mark =vase]
    |^  ::reminder, where does action var come from?? Our /sur file, of course!
        ::Our $-arm
        ^-  (quip card _this)
        ?+  mark  `this
            %gameuis-action             
                (handle-action !<(action vase))
            %handle-http-request  
                (handle-http !<([@ta inbound-request:eyre] vase))
         ==  ::End ?+  ::End $-arm
        ++  handle-action
            |=  act=action
                ^-  (quip card _this)
                ?-    -.act
                    ::Dummied, remove later
                    %push  `this
                    %pop  `this
                    ::Here, we set a basic state using a poke via the terminal. This will test our Sail render gates
                    %teststate
                    =/  p1  ^-  player  [~nodsup-sorlex 1 %spade %red]
                    =/  p2  ^-  player  [~miglex-todsup 2 %diamond %green]
                    =/  row1  ^-  boardrow  ~[[%white %empty] [%black %spade] [%white %diamond]]
                    =/  row2  ^-  boardrow  ~[[%black %spade] [%white %diamond] [%black %diamond]]
                    =/  row3  ^-  boardrow  ~[[%white %spade] [%black %empty] [%white %empty]]
                    =/  theboard  ^-  board  ~[row1 row2 row3]
                    =/  theplayermap  (my ~[[1 p1] [2 p2]])
                    :_  %=  this  playmap  theplayermap  gameboard  theboard  ==  ~
                    ::The state can also be reset with a poke, should be choose to. Tests the Sail Null Case.
                    %clearstate
                    :_  %=  this  playmap  *playerinfo  gameboard  *board  ==  ~
                == ::End ?-
        ++  handle-http
            |=  [rid=@ta req=inbound-request:eyre]
                ^-  (quip card _this)
                :: if the request doesn't contain a valid session cookie
                :: obtained by logging in to landscape with the web logic
                :: code, we just redirect them to the login page
                ::
                ?.  authenticated.req
                    :_  this
                    (give-http rid [307 ['Location' '/~/login?redirect='] ~] ~)
                :: if it's authenticated, we test whether it's a GET or
                :: POST request.
                ::
                    ?+  method.request.req
                    :: if it's neither, we give a method not allowed error.
                        :_  this
                        %^    give-http
                            rid
                            :-  405
                            :~  ['Content-Type' 'text/html']
                                ['Content-Length' '31']
                                ['Allow' 'GET, POST']
                            ==
                        (some (as-octs:mimes:html '<h1>405 Method Not Allowed</h1>'))
                    :: if it's a get request, we call our index.hoon file
                    :: with the current app state to generate the HTML and
                    :: return it. (we'll write that file in the next section)
                    ::
                        %'GET'
                        :_  this(page *^page)  ::Slam sample state into the gate. 
                        (make-200 rid (fe-board bowl page gameboard playmap))
                    == ::End ?+ and End arm
        ++  make-200
            |=  [rid=@ta dat=octs]
            ^-  (list card)
                %^    give-http
                    rid
                :-  200
                :~  ['Content-Type' 'text/html']
                    ['Content-Length' (crip ((d-co:co 1) p.dat))]
                ==
                [~ dat]
        ++  give-http
            |=  [rid=@ta hed=response-header:http dat=(unit octs)]
            ^-  (list card)
                :~  [%give %fact ~[/http-response/[rid]] %http-response-header !>(hed)]
                    [%give %fact ~[/http-response/[rid]] %http-response-data !>(dat)]
                    [%give %kick ~[/http-response/[rid]] ~]
                ==
    --  ::End |^
++  on-peek
  |=  =path
  ^-  (unit (unit cage))
  ?+  path  (on-peek:default path)
    [%x %values ~]  ``noun+!>(values)
  ==
++  on-watch
  |=  =path
  ^-  (quip card _this)
  `this
  ::?>  ?=([%values ~] path)
  :::_  this
  ::[%give %fact ~ %gameuis-update !>(`update`[%init values])]~
++  on-arvo   on-arvo:default
++  on-leave  on-leave:default
++  on-agent  on-agent:default
++  on-fail   on-fail:default
--