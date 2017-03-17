#!/usr/bin/env ruby -w
require 'socket'

class Server
  IP = 'localhost'
  PORT = 12345

  def initialize()
    @tcp_server = TCPServer.open(IP, PORT )

    @udp_socket = UDPSocket.new
    @udp_socket.bind(IP, PORT )

    @connections = Hash.new
    @connections[:clients] = Hash.new
    @connections[:udp_ports] = Hash.new

    listenUDP
    run

    @udp_response.join
  end

  def run
    loop {
      Thread.start(@tcp_server.accept) do | client |
        nick_name, udp_port = client.gets.chomp.split('|')
        @connections[:udp_ports][udp_port.to_i] = nick_name
        nick_name = nick_name.to_sym

        @connections[:clients].each do |other_name, other_client|
          if nick_name == other_name || client == other_client
            client.puts "This nickname already exist"
            Thread.kill self
          end
        end

        puts "#{nick_name} #{client}"
        @connections[:clients][nick_name] = client
        client.puts "Connection established, Thank you for joining! Happy chatting"
        listenTCP(nick_name, client )
      end
    }.join
  end

  def listenUDP
    @udp_response = Thread.new do
      loop {
        msg, addr = @udp_socket.recvfrom(1024)
        @connections[:udp_ports].each_key do |port|
          unless port == addr[1]
            @udp_socket.send("#{@connections[:udp_ports][addr[1]]}: #{msg}", 0, IP, port)
          end
        end
      }
    end
  end

  def listenTCP(username, client )
    loop {
      msg = client.gets.chomp
      @connections[:clients].each do |other_name, other_client|
        unless other_name == username
          other_client.puts "#{username.to_s}: #{msg}"
        end
      end
    }
  end
end

Server.new()
