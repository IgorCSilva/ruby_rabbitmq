# RubyRabbitmq

A simple ruby application using RabbitMQ to send messages.
Here we have three services:
- **rabbitmq:** the message broker
- **ruby_rabbitmq_publisher:** the ruby implementation to send messages
- **ruby_rabbitmq_consumer:** the ruby implementation to receive messages

**Obs.:** Don't forget to update the code in this tutorial to replace the application name to your application name.

## Docker configurations

Set the docker-compose.yaml file with RabbitMQ configuration.
```yaml
version: '3'

services:

  rabbitmq:
    image: rabbitmq:3-management
    ports:
      - "5672:5672"
      - "15672:15672"
    environment:
      RABBITMQ_DEFAULT_USER: user
      RABBITMQ_DEFAULT_PASS: password

  ruby_rabbitmq_publisher:
    build: .
    container_name: ruby_rabbitmq_publisher
    volumes:
      - .:/app
    depends_on:
      - rabbitmq
    environment:
      RABBITMQ_URL: amqp://user:password@rabbitmq:5672


  ruby_rabbitmq_consumer:
    build: .
    container_name: ruby_rabbitmq_consumer
    volumes:
      - .:/app
    depends_on:
      - rabbitmq
    environment:
      RABBITMQ_URL: amqp://user:password@rabbitmq:5672

```
**Obs.:** Put credentials in docker-compose file isn't a safe way. After update your code to use `.env` file.

The Dockerfile:
```yaml

# Use the official Ruby image from Docker Hub.
FROM ruby:3.3.1

# Set the working directory inside the container.
WORKDIR /app

# Copy the Gemfile and Gemfile.lock into the container.
COPY Gemfile* ruby_rabbitmq.gemspec ./

# Copy the version file into the container.
COPY lib/ruby_rabbitmq/version.rb ./lib/ruby_rabbitmq/version.rb

# Install dependencies using Bundler.
RUN bundle install

# Copy the rest of the application code into the container.
COPY . .

# Keeps the container available.
CMD ["tail", "-f", "/dev/null"]
```

## Configuration
We'll use bunny to interact with RabbitMQ.

Add gem to Genfile:
```rb
gem "bunny", "~> 2.22.0"
```

## Publisher

Create a publisher file.
- lib/app/publisher.rb
```rb

require 'bunny'

# Start connection.
connection = Bunny.new(ENV['RABBITMQ_URL'])
connection.start()

# Create channel.
channel = connection.create_channel()
queue = channel.queue("test_queue")

# Send messages.
10.times do |i|
  message = "Message #{i}."

  # Publish.
  queue.publish(message)

  puts " [x] Sent '#{message}'."
end

# Stop connection.
connection.close()
```

## Consumer

Create the consumer file.
- lib/app/consumer.rb
```rb

require 'bunny'

# Start connection.
connection = Bunny.new(ENV['RABBITMQ_URL'])
connection.start()

# Create channel.
channel = connection.create_channel()
queue = channel.queue("test_queue")

puts " [*] Waiting for messages. To exit press CTRL+C."

begin
  queue.subscribe(block: true) do |delivery_info, properties, body|
    puts " [x] Received '#{body}'."
  end

rescue Interrupt => _
  # Stop connection.
  connection.close
  exit(0)
end
```

## Running the application

Run all services:  
`docker-compose up --build`

You can access the RabbitMQ interface here: `http://localhost:15672`.  
Siging with defined credentials in docker-compose file.

Get inside the consumer container:  
`docker exec -it ruby_rabbitmq_consumer bash`

Run the consumer:  
`ruby lib/app/consumer.rb`

Get inside the publisher container:  
`docker exec -it ruby_rabbitmq_publisher bash`

Run the publisher:  
`ruby lib/app/publisher.rb`

At this point you should see the messages sent in consumer console.

## Simulate failure

Change the consumer code.
```rb

require 'bunny'

def start_consumer

  # Start connection.
  connection = Bunny.new(ENV['RABBITMQ_URL'], automatically_recover: true)
  connection.start()
  
  # Create channel.
  channel = connection.create_channel()
  queue = channel.queue("test_queue")
  
  puts " [*] Waiting for messages. To exit press CTRL+C."
  
  begin
    queue.subscribe(block: true) do |delivery_info, properties, body|
      puts " [x] Received '#{body}'."
    end
  
  rescue Interrupt => _
    # Stop connection.
    connection.close
    exit(0)
  end

rescue
  puts " [!] General Exception. Retrying in 5 seconds..."
  sleep 5
  retry
end

start_consumer()
```

Shutdown the RabbitMQ:  
`docker-compose stop rabbitmq`

Now, you'll see the retry messages.

Then start again:  
`docker-compose start rabbitmq`

Send the messages again from publisher and see them in consumer shell.

## Conclusion

You configured the RabbitMQ in a ruby application and sent messages from publisher to consumer. You're able to set RabbitMQ in your applications and keep learning without the need RabbitMQ local installation.