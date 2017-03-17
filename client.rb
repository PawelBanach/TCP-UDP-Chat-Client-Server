#!/usr/bin/env ruby -w
require 'socket'
require 'ipaddr'


class Client
  MULTICAST_ADDR = '224.6.8.11'
  BIND_ADDR = '0.0.0.0'
  IP = 'localhost'
  SERVER_PORT = 12345

  # Simulation of multimedia files
  ASCII_ART = "♪┏(°.°)┛┗(°.°)┓┗(°.°)┛┏(°.°)┓ ♪"


  def initialize()
    @udp_socket = UDPSocket.new
    @udp_socket.bind(IP, 0 )

    @tcp_socket = TCPSocket.open( IP, SERVER_PORT )

    #MULTICAST
    @multicast_udp_socket = UDPSocket.open
    @multicast_udp_socket.setsockopt(:IPPROTO_IP, :IP_ADD_MEMBERSHIP, bind_address)
    @multicast_udp_socket.setsockopt(:SOL_SOCKET, :SO_REUSEPORT, 1)
    @multicast_udp_socket.bind(BIND_ADDR, SERVER_PORT)

    listenTCP
    listenUDP
    listenMulticast

    connect
    send

    @request.join
    @tcp_response.join
    @udp_response.join
    @multicast_response.join
  end

  def listenTCP
    @tcp_response = Thread.new do
      loop {
        msg = @tcp_socket.gets.chomp
        puts "#{msg}"
      }
    end
  end

  def listenUDP
    @udp_response = Thread.new do
      loop {
        msg, _ = @udp_socket.recvfrom(1024)
        puts "#{msg}"
      }
    end
  end

  def listenMulticast
    @multicast_response = Thread.new do
      loop do
        msg, _ = @multicast_udp_socket.recvfrom(1024)
        puts "Multicast message from #{@name}: \n#{msg}"
      end
    end
  end

  def connect
    puts "Enter the nick:"
    @name = $stdin.gets.chomp
    @tcp_socket.puts( "#{@name}|#{@udp_socket.addr[1]}")
  end

  def bind_address
    IPAddr.new( MULTICAST_ADDR ).hton + IPAddr.new( BIND_ADDR ).hton
  end

  def send
    @request = Thread.new do
      loop {
        msg = $stdin.gets.chomp
        if msg == 'M'
          @udp_socket.send( ASCII_ART, 0, IP, SERVER_PORT )
        elsif msg == 'N'
          @multicast_udp_socket.send( ASCII_ART, 0, MULTICAST_ADDR, SERVER_PORT )
        else
          @tcp_socket.puts( msg )
        end
      }
    end
  end
end

Client.new()