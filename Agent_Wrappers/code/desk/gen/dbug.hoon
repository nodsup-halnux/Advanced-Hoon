::  Import library
/+  *dbug
:: Generator is used on Command Line. As follows:
:: 1  :app +dbug (dump entire state)
:: 2  :app +dbug %bowl (dump bowl)
:: 3  +dbug [%state 'hoon'] expose data in state
:: 4  +dbug [?(%incoming outgoing) specifics] details about subscribes

:: Say Generator, make a structure headtagged with %say
:-  %say
:: Gate call, sample is a struct. $: is the N-tuple builder
|=  $:  ::  environment
        *
        ::  inline arguments
        args=?(~ [what=?(%bowl %state) ~] [=poke ~])
        ::  named arguments
        ~
    ==
:: $ arm starts here. Return a head tagged cell with one of three
:: expressions.
:-  %dbug
?-  args
  :: No Args
  ~          [%state '']
  :: More specific subset, the bowl or state.
  [@ ~]      ?-(what.args %bowl [%bowl ~], %state [%state ''])

  [[@ *] ~]  poke.args
==