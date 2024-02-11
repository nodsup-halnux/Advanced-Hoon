## %Lick Vane, and IPC:

### Introduction:

In this tutorial, we investigate the `%lick` vane, which is used for Inter Process Communications between Dojo (through Vere), to another process running inside your OS. For these examples, we will be getting Unix and Urbit to talk to one another.

The following topics will be covered in this readme:

1) General Summary of Lick (just a summarization of Doc notes)

2) Studying and Running ~mopfel-winrux's [%slick](https://github.com/mopfel-winrux/slick/tree/main) - which connects Dojo to a python process to play a game of Snake in unix console.

3) Practical Work: Lets modify what was seen in %slick, to control VLC media player via command-line!

### Lick Notes:

#### API Ref Summary:







### Practical Example: Commandline Control of VLC Media Player:

VLC media player can be controlled by running it [headless](https://wiki.videolan.org/Documentation:Modules/rc/) (no GUI) on the unix command line. We will invoke our VLC by running `vlc -I rc  <path to a playlist>`. 

The goal is simple: Connect urbit to our VLC instance running in a terminal, and control what is playing by passing `next` `prev` and `seek <X>` commands via IPC using the %lick vane.

