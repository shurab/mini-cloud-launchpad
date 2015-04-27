require 'fog'

class LaunchpadController < ApplicationController
  WORD_PRESS_PARAMS = {
    :image_id   => 'ami-746c7731',
    :tags       => {'Name' => 'Bitnami-WordPress'},
    :flavor_id  => 'm3.medium',
    :groups     => 'default', # this security group inludes HTTP protocol
    :user       => 'ubuntu'}

  module Constants
    REGION          = 'us-west-1'
    SLEEP           = 30
    HOME_DIR        = `echo ~/`.strip.chomp("/")
    ACCESS_KEY_FILE = "#{HOME_DIR}/.ec2"
  end

  def new
  end

  def create
    # TODO:
    puts
    puts params.inspect
    puts

    #####################################
    session[:dns_name] = nil
    session[:instance_id] = nil
    thread = Thread.new do
      puts "Starting ec2 bitnami-wordpress-3.4.2-1 instance ..."
      launch_ec2_instance(WORD_PRESS_PARAMS)
    end

    # Wait till thread is finished
    puts "Wait till thread is finished"
    thread.join
    puts "Thread is finished"

    if thread.value != 0
      puts "Thread is failed to launch ec2 instance"
    else
      # puts "Sleep 60 secs."
      # sleep 60
      # puts 'Terminating instance ...'
      # @server.destroy if @server
      puts '------------------------------'
      puts @server.class
      puts @server.inspect
      puts @server.dns_name
      puts

      # session[:server] = @server
      session[:instance_id] = @server.id
      session[:dns_name] = @server.dns_name

      puts session[:instance_id]
      puts session[:dns_name]
      puts '------------------------------'
    end

    redirect_to launchpad_show_path
  end

  def show
  end

  def destroy
    # TODO
    puts '================================='
    # puts session[:server].class
    puts session[:instance_id]
    puts session[:dns_name]
    puts '================================='

    if session[:instance_id]
      connection = connect_to_amazon
      server = connection.servers.get(session[:instance_id])
      server.destroy

      session[:dns_name] = nil
      session[:instance_id] = nil
    end

    redirect_to launchpad_new_path, notice: 'Server successfully terminated!'
  end

private
  def connect_to_amazon
    lines = IO.readlines Constants::ACCESS_KEY_FILE
    access_key        = lines.first.strip.split("=")[1]
    secret_access_key = lines.last.strip.split("=")[1]

    Fog::Compute.new(
      :provider => 'AWS',
      :region => Constants::REGION,
      :aws_access_key_id => access_key,
      :aws_secret_access_key => secret_access_key)
  end

  def launch_ec2_instance(params)
    start_time = Time.now

    connection = connect_to_amazon
    puts "Creating a new instance..."
    @server = connection.servers.create(params)

    puts 'Wait for machine to be booted ...'
    @server.wait_for { ready? }

    puts 'Wait for machine to get an ip-address ...'
    @server.wait_for { !public_ip_address.nil? }

    until @server.ready?
      # wait for all services to start on remote VM
      puts "Waiting #{Constants::SLEEP} seconds for services to start on remote VM ..."
      Constants::SLEEP.times do
        sleep 1
        print "."
        STDOUT.flush
      end
    # else
    #    raise "Server timed out."
    end

    host = @server.dns_name
    puts "Remote host #{host} is up and running ..."
    puts "DNS name: #{host}"

    elapsed_time = (Time.now - start_time).to_i
    puts "elapsed_time: #{elapsed_time}"
    0
  rescue => e
    puts e.inspect
    puts e.backtrace
    -1
  end
end
