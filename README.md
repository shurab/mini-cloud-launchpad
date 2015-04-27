# mini-cloud-launchpad

A web application that asks the end user for their AWS security credentials. After the user presses submit,
the backend code should launch a Bitnami WordPress AMI and display the progress to the end user on the browser
(e.g., "Launching server" ... "Server up and running").  Once the server is available, it should display a
clickable link to access the WordPress application (http:// ...) and a button to stop the VM.

## Prerequisites

* Ruby (2.2.2)
* Rails (4.1.x)
* Redis
* Sidekiq
* ~/.ec2 file with AWS accout credentials
  <pre>
  ACCESS_KEY=AK...
  SECRET_ACCESS_KEY=...
  </pre>


## How install and run app

```
git clone git@github.com:shurab/mini-cloud-launchpad.git
cd mini-cloud-launchpad/
bundle

```
Then in terminal from project directory start web app

```
rails s
```

Open another terminal in project directory and check that redis server up and running and start sidekiq

```
redis-cli ping
bundle exec sidekiq
```
The last step is to open in your browser app URL: http://localhost:3000/

Before launching server on Amanon make sure that your ~/.ec2 file has valid AWS credentials, and selected security group includes inbound HTTP port 80.

In my tests launching Bitnami Wrd Press server usually takes about 2 - 3 mins.
