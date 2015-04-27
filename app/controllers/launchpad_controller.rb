class LaunchpadController < ApplicationController
  def new
    @flavor_options = [['m3.medium', "m3.medium"], ['m3.large', 'm3.large']]
  end

  def create
    options = {
      :image_id   => "#{params['image_id']}",
      :tags       => {'Name' => "#{params['tags']}"},
      :flavor_id  => "#{params['flavor_id']}",
      :groups     => "#{params['groups']}", # this security group must include HTTP protocol
      :user       => 'ubuntu'
    }
    puts options.inspect
    # fail

    LaunchWorker.perform_async('new', options)
    redirect_to launchpad_show_path
  end

  def show
    @instance_id = redis.get("launcher:instance_id")
    @dns_name    = redis.get("launcher:dns_name")
  end

  def destroy
    LaunchWorker.perform_async('destroy', {})
    redirect_to launchpad_new_path, notice: 'Server successfully terminated!'
  end

private
  def redis
    @redis ||= Redis.new
  end
end
