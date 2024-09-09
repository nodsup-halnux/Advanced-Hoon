from noun import *
import socket
import subprocess
import time

##Decodes data from our connected socket. So From Urbit -> python
def cue_data(data):
    #likely, offset +5, little-endian
    #Jam Format:
    #[1B: version][4B: size of jam in bytes][nB: jammed data]
    x = cue(int.from_bytes(data[5:], 'little'))
    print("cue_data output:")
    mark = intbytes(x.head).decode()
    print(mark)
    noun = x.tail
    print(noun)
    print("---")

    return (mark,noun)

##Encodes our response for socket. So From Python -> Urbit
def jam_result(mark, msg):
    mark = int.from_bytes(mark.encode(), 'little')
    noun = int.from_bytes(msg.encode(), 'little')
    return intbytes(jam(Cell(mark, noun)))

#Puts everything together and forms our response frame
#to be written to the socket file.
def make_output(jammed):
    length = len(jammed).to_bytes(4, 'little')
    print("length:" + str(length))
    version = (0).to_bytes(1, 'little')
    print("version:" + str(version))
    return version+length+jammed

#Main-like method
if __name__ == "__main__":
    # Define the command to launch VLC
    vlc_command = ['vlc', '-I', 'rc', '--rc-host', 'localhost:8888', "./samples.xspf"]
    # Launch VLC as a subprocess
    vlc_process = subprocess.Popen(vlc_command)
    # Create a socket for IPC
    ipc_socket = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
    ipc_socket.connect(('localhost', 8888))  # Connect to VLC's remote control interface
    # Example: Send a command to VLC
    print("Timer starting...")
    time.sleep(8)
    print("bye...!!!")
    ipc_socket.close()
    # Optionally, wait for VLC process to finish
    vlc_process.wait()
