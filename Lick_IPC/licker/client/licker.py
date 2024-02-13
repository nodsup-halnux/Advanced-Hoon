from noun import *
import socket

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

#so sockets are just files in our pier.
# this makes sense, as everything is a file in unix.
sock_path = '/home/user/Documents/CodeProjects/AdvancedHoon/med/.urb/dev/licker/licker.sock'

## Template library call
sock = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)

## the socket connection just points to our file we made.
sock.connect(sock_path)

## Not computationally efficient
while True:
    try:
        ## Try reading a kilobyte from file
        data = sock.recv(1024)
        ##  parse the raw data
        mark, noun = cue_data(data)
    except TimeoutError:
        pass

    # End loop if we don't pull a noun mark
    if (mark != 'noun'):
      pass

    # If we did, start decoding.
    msg = intbytes(noun).decode()
    # Look for ping
    if (msg != 'ping'):
      pass
  
    print('ping!')

    #Our response
    jammed = jam_result('noun', 'pong')
    output = make_output(jammed)
    sock.send(output)
