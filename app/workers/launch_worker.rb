require 'fog'

class LaunchWorker
  include Sidekiq::Worker

  def perform(action, params)
    puts "action: #{action}"
    puts "params: #{params}"

    if action == 'new'
      puts "Launch instance!"

      Sidekiq.redis do |conn|
         conn.del("launcher:instance_id")
         conn.del("launcher:dns_name")
       end

      puts "Starting ec2 bitnami-wordpress-3.4.2-1 instance ..."
      value = launch_ec2_instance(params)
      if value != 0
        puts "Failed to launch ec2 instance"
        # TODO:
      else
        Sidekiq.redis do |conn|
          conn.set("launcher:instance_id", @server.id)
          conn.set("launcher:dns_name", @server.dns_name)
        end
      end
    else # terminate
      puts "Terminate instance!"
      # TODO:
      Sidekiq.redis do |conn|
        @instance_id = conn.get("launcher:instance_id")
        @dns_name    = conn.get("launcher:dns_name")
      end
      if @instance_id
        connection = connect_to_amazon
        server = connection.servers.get(@instance_id)
        server.destroy
      end
      Sidekiq.redis do |conn|
        conn.del("launcher:instance_id")
        conn.del("launcher:dns_name")
      end
    end
  end

  module Constants
    REGION          = 'us-west-1'
    SLEEP           = 30
    HOME_DIR        = `echo ~/`.strip.chomp("/")
    ACCESS_KEY_FILE = "#{HOME_DIR}/.ec2"
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

    if @server.ready?
      # wait for all services to start on remote VM
      puts "Waiting #{Constants::SLEEP} seconds for services to start on remote VM ..."
      Constants::SLEEP.times do
        sleep 1
        print "."
        STDOUT.flush
      end
    else
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
