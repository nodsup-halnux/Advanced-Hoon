from noun import *
import socket

def cue_data(data):
    #likely, offset +5, little-endian
    x = cue(int.from_bytes(data[5:], 'little'))
    mark = intbytes(x.head).decode()
    noun = x.tail
    return (mark,noun)

def jam_result(mark, msg):
    mark = int.from_bytes(mark.encode(), 'little')
    noun = int.from_bytes(msg.encode(), 'little')
    return intbytes(jam(Cell(mark, noun)))

def make_output(jammed):
    length = len(jammed).to_bytes(4, 'little')
    version = (0).to_bytes(1, 'little')
    return version+length+jammed

#so sockets are just files in our pier.
# this makes sense, as everything is a file in unix.
sock_path = '/home/user/zod/.urb/dev/licker/licker.sock'
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

    # If we pull something other than a noun mark
    if (mark != 'noun'):
      pass

    # Else, we decode
    msg = intbytes(noun).decode()
    # Look for ping
    if (msg != 'ping'):
      pass
  
    print('ping!')

    #Our response
    jammed = jam_result('noun', 'pong')
    output = make_output(jammed)
    sock.send(output)
