/+  default-agent
|%
+$  card  card:agent:gall
--
::Notice: No state!!
^-  agent:gall
|_  =bowl:gall
+*  this  .
    def   ~(. (default-agent this %|) bowl)
::
++  on-init
  ^-  (quip card _this)
  :_  this
  :: A pass card to %arvo, directed at %lick vane
  ::%l just corresponds to lick.
  :: %spin is a userspace task - opens an IPC port
  ::our socket has a name, and that is [ ~ 'licker.sock']
  [%pass /lick %arvo %l %spin /'licker.sock']~
::
++  on-poke
  |=  [=mark =vase]
  ^-  (quip card _this)
  :: Positive assertion. If we decode vase, do we get noun ping?
  ?>  ?=([%noun %ping] [mark !<(@tas vase)])
  ::  %spit is a task that sends a noun to our IPC port
  :: %our input is %noun and %ping, being sent over
  :_  this
  [%pass /spit %arvo %l %spit /'licker.sock' %noun %ping]~

::  On arvo handles responses from our Arvo OS.
++  on-arvo
  |=  [=wire sign=sign-arvo]
  ^-  (quip card _this)
  ::A soak is a gift (response) from our named socket.
  ::Inverted IF statement
  ?.  ?=([%lick %soak *] sign)  (on-arvo:def +<)
  :: True case not sure about this notation?
  ?+    [mark noun]:sign        (on-arvo:def +<)
  :: (slog a) makes a gate, a is a tang, we feed it [~ this] agent
    ::just letting the user know status in console
    [%connect ~]     ((slog 'socket connected' ~) `this)
    [%disconnect ~]  ((slog 'socket disconnected' ~) `this)
    [%error *]       ((slog leaf+"socket {(trip ;;(@t noun.sign))}" ~) `this)
    ::Our actual response from python, once we are gifted.
    [%noun %pong]    ((slog 'pong!' ~) `this)
  ==

++  on-save   on-save:def
++  on-load   on-load:def
++  on-watch  on-watch:def
++  on-leave  on-leave:def
++  on-peek   on-peek:def
++  on-agent  on-agent:def
++  on-fail   on-fail:def
--
