from OSC import OSCClient, OSCMessage, OSCServer, OSCMultiClient
import types
import time
import threading

SC_SYNTH_PORT = 57110
SC_LANG_PORT = 57120
PS_CORREL_PORT_1 = 36000
PS_CORREL_PORT_2 = 36001
PS_CORREL_PORT_3 = 36002
PS_CORREL_PORT_4 = 36003

def handle_blurt(self, path=None, tags=None, args=None, source=None):
    print "request", path, tags, args
    print "remote source", source
    print "local client", self.client.address()
    print "local server", self.socket.getsockname(), self.server_address

def null_handler(self, path=None, tags=None, args=None, source=None):
    pass

#hack to eliminate the possibility that rogue exceptions are poisoning this fucking thing
def handle_error(self,request,client_address):
    print "ERROR",self,request,client_address

#OSCServer.timeout = 1.0
OSCServer.timeout = 0.01

sc_synth_client = OSCClient()
sc_synth_client.connect( ("127.0.0.1", SC_SYNTH_PORT)) #or SC_SYNTH_PORT?
sc_synth_facing_server = OSCServer(("127.0.0.1", PS_CORREL_PORT_1), client=sc_synth_client)
sc_synth_facing_server.addDefaultHandlers()
sc_synth_facing_server.handle_blurt = types.MethodType(handle_blurt, sc_synth_facing_server)
sc_synth_facing_server.running = True
sc_synth_facing_server.addMsgHandler("default", sc_synth_facing_server.handle_blurt)
sc_synth_facing_server.addMsgHandler("/hello", sc_synth_facing_server.handle_blurt)

sc_synth_client.sendto(OSCMessage("/notify", 1),("127.0.0.1", SC_SYNTH_PORT))
# other_sc_synth_client = OSCClient()
# other_sc_synth_client.sendto(OSCMessage("/notify"),("127.0.0.1", SC_SYNTH_PORT))

print "sc_synth_facing_server", sc_synth_facing_server.server_address, sc_synth_client.address(), sc_synth_facing_server.getOSCAddressSpace()

sc_lang_facing_server = OSCServer(("127.0.0.1", PS_CORREL_PORT_2))
sc_lang_client = sc_lang_facing_server.client
sc_lang_facing_server.addDefaultHandlers()
sc_lang_facing_server.handle_blurt = types.MethodType(handle_blurt, sc_lang_facing_server)
sc_lang_facing_server.running = True
sc_lang_facing_server.addMsgHandler("default", sc_lang_facing_server.handle_blurt)
sc_lang_facing_server.addMsgHandler("/hello", sc_lang_facing_server.handle_blurt)

sc_lang_client.sendto(OSCMessage("/notify"),("127.0.0.1", SC_LANG_PORT))

print "sc_lang_facing_server", sc_lang_facing_server.server_address, sc_lang_client.address(), sc_lang_facing_server.getOSCAddressSpace()

general_server = OSCServer(("127.0.0.1", PS_CORREL_PORT_3))
general_client = general_server.client
general_server.addDefaultHandlers()
general_server.handle_blurt = types.MethodType(handle_blurt, general_server)
general_server.running = True
general_server.addMsgHandler("default", general_server.handle_blurt)
general_server.addMsgHandler("/hello", general_server.handle_blurt)

print "general_server", general_server.server_address, general_client.address(), general_server.getOSCAddressSpace()

multi_client = OSCMultiClient()
multi_server = OSCServer(("127.0.0.1", PS_CORREL_PORT_4 ), client=multi_client)
multi_server.addDefaultHandlers()
multi_server.handle_blurt = types.MethodType(handle_blurt, multi_server)
multi_server.running = True
multi_server.addMsgHandler("default", multi_server.handle_blurt)
multi_server.addMsgHandler("/hello", multi_server.handle_blurt)

print "multi_server", multi_server.server_address, multi_client.address(), multi_server.getOSCAddressSpace()

# i = 0
# ptime = time.time()
# while True:
#     i=i+1
#     ntime = time.time()
#     deltime = ntime - ptime
#     if deltime>=1.0:
#         print i, deltime
#         ptime = ntime
#     sc_synth_facing_server.handle_request()
#     sc_lang_facing_server.handle_request()
#     general_server.handle_request()
#     multi_server.handle_request()
#
# print "NOOOOOO"
# sc_synth_facing_server.close()
# sc_lang_facing_server.close()
# general_server.close()
# multi_server.close()


synth_server_thread = threading.Thread( target = sc_synth_facing_server.serve_forever )
synth_server_thread.start()

print "serving1"

lang_server_thread = threading.Thread( target = sc_lang_facing_server.serve_forever )
lang_server_thread.start()

print "serving2"

general_server_thread = threading.Thread( target = general_server.serve_forever )
general_server_thread.start()

print "serving3"

multi_server_thread = threading.Thread( target = general_server.serve_forever )
multi_server_thread.start()

print "serving4"
