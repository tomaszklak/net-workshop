#!/bin/env ruby

require 'socket'

def bold(s,c)
  c ? "\e[1m#{s}\e[22m" : s
end

hostname=Socket.gethostname
p="fd00:"

machines = [
  ["client1", "#{p}1::10"],
  ["server1", "#{p}1::20", "#{p}2::20"],
  ["server2", "#{p}3::30", "#{p}2::30"],
  ["client2", "#{p}3::40"],
]

def reachable?(ip)
  system 'ping6', '-c', '1', '-W', '1', ip, [:out, :err] => '/dev/null'
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
