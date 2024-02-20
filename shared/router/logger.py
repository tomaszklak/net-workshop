from netfilterqueue import NetfilterQueue
import scapy.all as scapy
import selectors

sel = selectors.DefaultSelector()

def print_packet(pkt):
    ip = scapy.IP(pkt.get_payload())
    print(ip.src, " -> ", ip.dst, ", protocol: ", ip.proto)
    if ip.proto == 6:
        tcp = ip["TCP"]
        print("    TCP sport: ", tcp.sport, ", dport: ", tcp.dport, ", flags: ", tcp.flags)
    elif ip.proto == 1:
        icmp = ip["ICMP"]
        print("    ICMP type: ", icmp.type , ", id: ", icmp.id, ", seq: ", icmp.seq)

def log_nat(pkt):
    print("nat postrouting chain", end=" ")
    print_packet(pkt)
    pkt.set_mark(1)
    pkt.repeat()

def log_filter(pkt):
    print("filter forward chain", end=" ")
    print_packet(pkt)
    pkt.accept()

nfqueue1 = NetfilterQueue()
nfqueue1.bind(1, log_nat)
nfqueue2 = NetfilterQueue()
nfqueue2.bind(2, log_filter)

def run(nfqueue):
    def run_queue():
        nfqueue.run(block=False)
    return run_queue

sel.register(nfqueue1.get_fd(), selectors.EVENT_READ, run(nfqueue1))
sel.register(nfqueue2.get_fd(), selectors.EVENT_READ, run(nfqueue2))

try:
    while True:
        events = sel.select()
        for key, mask in events:
            callback = key.data
            callback()
except KeyboardInterrupt:
    nfqueue1.unbind()
    nfqueue2.unbind()