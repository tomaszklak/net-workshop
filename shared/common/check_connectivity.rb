#!/bin/env ruby

require 'socket'

def bold(s,c)
  c ? "\e[1m#{s}\e[22m" : s
end

hostname=Socket.gethostname
p="192.168."

machines = [
  ["client1", "#{p}57.11"],
  ["server1", "#{p}57.22", "#{p}58.33"],
  ["server2", "#{p}58.44", "#{p}59.55"],
  ["client2", "#{p}59.66"],
]

def reachable?(ip) 
  system 'ping', '-c', '1', ip, [:out, :err] => '/dev/null'
end

machines.each do |l|
  l[1..].each do |ip|
    if l[0] != hostname
      reachable = reachable?(ip)
      puts bold("Can connect from #{hostname} to #{l[0]} on #{ip}: #{reachable}", reachable)
    end
  end
end
puts
