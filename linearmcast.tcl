# Create scheduler
#Create an event scheduler wit multicast turned on
set ns [new Simulator -multicast on]
$ns multicast

global nummsg
set nummsg 1
#Turn on Tracing
set tf [open output.tr w]
$ns trace-all $tf

# Turn on nam Tracing
set fd [open mcast.nam w]
$ns namtrace-all $fd

# Create nodes
set OLDCOMM {
	set n(0) [$ns node]
set n(1) [$ns node]
set n(2) [$ns node]
set n(3) [$ns node]
set n(4) [$ns node]
set n(5) [$ns node]
set n(6) [$ns node]
set n(7) [$ns node]
}
global n
#set i 0
for {set i 0} {$i < 80} {incr i} {
	set n($i) "[$ns node]"
}
 
# Create links
$ns duplex-link $n(0) $n(1) 1.5Mb 10ms DropTail
$ns duplex-link $n(0) $n(2) 1.5Mb 10ms DropTail


#create the rest of the links
for {set i 1} {$i < 40} {incr i} {
      $ns duplex-link $n($i) $n([expr 2*($i)%80]) 1Mb 10ms DropTail
      $ns duplex-link $n($i) $n([expr (2*($i)+1)%80]) 1Mb 10ms DropTail
}


# Routing protocol: say distance vector
#Protocols: CtrMcast, DM, ST, BST
set mproto DM
set mrthandle [$ns mrtproto $mproto {}]

# Allocate group addresses
set group1 [Node allocaddr]
set group2 [Node allocaddr]

# UDP Transport agent for the traffic source
set udp0 [new Agent/UDP]
$ns attach-agent $n(0) $udp0
$udp0 set dst_addr_ $group1
$udp0 set dst_port_ 0
set cbr1 [new Application/Traffic/CBR]
$cbr1 attach-agent $udp0

# Transport agent for the traffic source
set udp1 [new Agent/UDP]
$ns attach-agent $n(1) $udp1
$udp1 set dst_addr_ $group2
$udp1 set dst_port_ 0
set cbr2 [new Application/Traffic/CBR]
$cbr2 attach-agent $udp1


#$ns at 0.2 "Graph"
set g [open graph.tr w]
set g1 [open graph1.tr w]

proc Graph {} {
	global ns g g1 nummsg
	set time 0.5
	set now [$ns now]
	puts $::nummsg
	puts $g "$now [expr log($nummsg)]"
	puts $g1 "$now [expr $nummsg]"
	#puts $g1 "[expr rand()*8] [expr rand()*6]"
	$ns at [expr $now+$time] "Graph"

}

proc increase {} {
	global ns g g1 nummsg
	incr nummsg
}

proc decrease {} {
	global ns g g1 nummsg
	incr nummsg -1
}

# Create receiver
set rcvr1 [new Agent/Null]
$ns attach-agent $n(5) $rcvr1
$ns at 1.0 "$n(5) join-group $rcvr1 $group1"
$ns at 1.0 "increase"


set rcvr2 [new Agent/Null]
$ns attach-agent $n(6) $rcvr2
$ns at 1.5 "$n(6) join-group $rcvr2 $group1"
$ns at 1.5 "increase"

set rcvr3 [new Agent/Null]
$ns attach-agent $n(7) $rcvr3
$ns at 2.0 "$n(7) join-group $rcvr3 $group1"
$ns at 2.0 "increase"
#$ns duplex-link $n(4) $n(6) 1.5Mb 10ms DropTail


set rcvr4 [new Agent/Null]
$ns attach-agent $n(5) $rcvr1
$ns at 2.5 "$n(5) join-group $rcvr4 $group2"
$ns at 2.5 "increase"

set rcvr5 [new Agent/Null]
$ns attach-agent $n(6) $rcvr2
$ns at 3.0 "$n(6) join-group $rcvr5 $group2"
$ns at 3.0 "increase"
$ns attach-agent $n(79) $rcvr2
$ns at 3.0 "$n(79) join-group $rcvr5 $group2"
$ns at 3.0 "increase"

set rcvr6 [new Agent/Null]
$ns attach-agent $n(7) $rcvr3
$ns at 3.5 "$n(7) join-group $rcvr6 $group2"
$ns at 3.5 "increase"

$ns at 4.0 "$n(5) leave-group $rcvr1 $group1"
$ns at 4.5 "$n(6) leave-group $rcvr2 $group1"
$ns at 5.0 "$n(7) leave-group $rcvr3 $group1"
$ns at 4.0 "increase"
$ns at 4.5 "increase"
$ns at 5.0 "increase"

$ns at 5.5 "$n(5) leave-group $rcvr4 $group2"
$ns at 6.0 "$n(6) leave-group $rcvr5 $group2"
$ns at 6.5 "$n(7) leave-group $rcvr6 $group2"
$ns at 5.5 "increase"
$ns at 6.0 "increase"
$ns at 6.5 "increase"
 
# Schedule events
$ns at 0.0 "Graph"
$ns at 0.5 "$cbr1 start"
$ns at 9.5 "$cbr1 stop"

$ns at 0.5 "$cbr2 start"
$ns at 9.5 "$cbr2 stop"

#post-processing
$ns at 10.0 "finish"
proc finish {} {
   global ns tf
   global ns g g1
   $ns flush-trace
   close $tf 
   close $g 
   close $g1
   #exec nam mcast.nam &
   exit 0
}

# For nam
#Colors for packets from two mcast groups
$ns color 10 red
$ns color 11 green
$ns color 30 purple
$ns color 31 green

# Manual layout: order of the link is significant!
#$ns duplex-link-op $n(0) $n(1) orient right
#$ns duplex-link-op $n(0) $n(2) orient right-up
#$ns duplex-link-op $n(0) $n(3) orient right-down

# Show queue on simplex link n(0)->n(1)
#$ns duplex-link-op $n(2) $n(3) queuePos 0.5

# Group 0 source
$udp0 set fid_ 10
$n(0) color red
$n(0) label "Source 1"

# Group 1 source
$udp1 set fid_ 11
$n(1) color green
$n(1) label "Source 2"

$n(5) label "Receiver 1"
$n(5) color blue
$n(6) label "Receiver 2"
$n(6) color blue
$n(7) label "Receiver 3"
$n(7) color blue 

#$n(2) add-mark m0 red
#$n(2) delete-mark m0"

# Animation rate
$ns set-animation-rate 3.0ms

$ns run