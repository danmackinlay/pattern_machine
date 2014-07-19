from OSC import OSCClient, OSCMessage, OSCServer
#Next return_port?

SC_SYNTH_PORT = 57110
SC_LANG_PORT = 57120
PS_CORREL_PORT_1 = 36000
PS_CORREL_PORT_2 = 36001
PS_CORREL_PORT_3 = 36002
PS_CORREL_PORT_4 = 36003

client0 = OSCClient()
client1 = OSCClient()
client2 = OSCClient()
client3 = OSCClient()
client4 = OSCClient()
client5 = OSCClient()
clientS = OSCClient()
client0.connect( ("127.0.0.1", 36000))
client1.connect( ("127.0.0.1", 36001))
client2.connect( ("127.0.0.1", 36002))
client3.connect( ("127.0.0.1", 36002))
client4.connect( ("127.0.0.1", 36003))
client5.connect( ("127.0.0.1", 36003))
clientS.connect( ("127.0.0.1", 57120))

print "subscribing"
client4.send(OSCMessage("/subscribe"))
client5.send(OSCMessage("/subscribe"))

for i in range(5): 
    print i
    # does not get through to pyOSC
    try:
        print "client0"
        m = OSCMessage("/hello")
        m.extend([0,i])
        client0.send(m)
    except Exception, e:
        print i, e
    # does not get through to pyOSC
    try:
        print "client1"
        m = OSCMessage("/hello")
        m.extend([1,i])
        client1.send(m)
    except Exception, e:
        print i, e
    # Almost all these messages will get through to pyOSC
    try:
        print "client2"
        m = OSCMessage("/hello")
        m.extend([2,i])
        client2.send(m)
    except Exception, e:
        print i, e
    # the first couple of these get through to pyOSC
    try:
        print "client3"
        m = OSCMessage("/hello")
        m.extend([3,i])
        client3.send(m)
    except Exception, e:
        print i, e
    try:
        print "client4"
        m = OSCMessage("/hello")
        m.extend([4,i])
        client4.send(m)
    except Exception, e:
        print i, e
    try:
        print "client5"
        m = OSCMessage("/hello")
        m.extend([5,i])
        client5.send(m)
    except Exception, e:
        print i, e
    # gets though to sclang
    try:
        print "clientS"
        m = OSCMessage("/hello")
        m.extend(["S",i])
        print clientS.send(m)
    except Exception, e:
        print i, e