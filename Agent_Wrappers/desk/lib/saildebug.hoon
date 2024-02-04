/-  *ourapp
/+  default-agent
/=  indexdebug  /app/frontend/indexdebug

|%
++  agent  
    |=  =agent:gall
    ^-  agent:gall
    ::!.
    |_  =bowl:gall
        :: agent sample above is fed a bowl, and ref'ed by ag.
      +*  this  .
          ag    ~(. agent bowl)
          default  ~(. (default-agent this %|) bowl)
      ::  Poke Arm - most fleshed out because we interact this way
      ++  on-init
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  on-init:ag  [cards this]
      ++  on-save   on-save:ag
      ++  on-load
        |=  old-state=vase
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-load:ag old-state)  [cards this]
      ++  on-poke
        |=  [=mark =vase]
          ^-  (quip card:agent:gall agent:gall)
          |^  ::reminder, where does action var come from?? Our /sur file, of course!
            ::Our $-arm
            ^-  (quip card:agent:gall agent:gall)::(quip card _this)
            ?+  mark              
                :: Null Case, just pass through!
                =^  cards  agent  (on-poke:ag mark vase)  [cards this]
                :: Else, its an httprequest, deal with it.
                %handle-http-request
                :: We don't even need this in a separate arm. 
                :: Can be refactored more simply.
                    (handle-http !<([@ta inbound-request:eyre] vase))
            ==  ::End ?+  
            ::End $-arm
            ++  handle-http
              |=  [rid=@ta req=inbound-request:eyre]
                ^-  (quip card:agent:gall agent:gall)::(quip card _this)
                :: if the request doesn't contain a valid session cookie
                :: obtained by logging in to landscape with the web logic
                :: code, we just redirect them to the login page
                ::
                ?.  authenticated.req
                    :_  ::this
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
                        ::Here we have a serious problem. The agent core is our
                        ::Input, but we need the state for our debug display.
                        ::This would be a complicated scry request to achieve??
                        (make-200 rid (indexdebug bowl page))
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
          -- ::End of barket |^
      ::End of our |= $ arm.
      :: On peek returns a cage, not a `this!!
      ++  on-peek   |=(path ~)
      ++  on-watch
        |=  =path
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-watch:ag path)  [cards this]
      ++  on-leave
        |=  =path
        ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-leave:ag path)  [cards this]
        ++  on-agent
        |=  [=wire =sign:agent:gall]
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-agent:ag wire sign)  [cards this]
      :: Pass Through
        ++  on-arvo
        |=  [=wire =sign-arvo]
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-arvo:ag wire sign-arvo)  [cards this]
      ++  on-fail
        |=  [=term =tang]
          ^-  (quip card:agent:gall agent:gall)
          =^  cards  agent  (on-fail:ag term tang)  [cards this]
    --
--