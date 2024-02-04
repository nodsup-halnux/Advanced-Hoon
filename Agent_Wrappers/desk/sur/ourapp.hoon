|%
+$  action
  $%  [%push target=@p value=@]
      [%pop target=@p]
      [%teststate target=@p]
      [%clearstate target=@p]
  ==
+$  update
  $%  [%init values=(list @)]
  ==
+$  page  [sect=@t success=?]
::Rudimentary board structures
+$  boarddims  [rows=@ud cols=@ud]
+$  colours  $?  %black  %white  %red  %green  %blue  ==
+$  tokentypes  $?  %club  %heart  %spade  %diamond  %empty  ==
+$  boardsquare  [bcolor=colours ppiece=tokentypes]
+$  boardrow  (list boardsquare)
+$  board  (list boardrow)
::For players
+$  player  [name=@p pnum=@ud token=tokentypes colour=colours]
+$  playerinfo  (map @ud player)
+$  playerorder  (map @p @ud)
--