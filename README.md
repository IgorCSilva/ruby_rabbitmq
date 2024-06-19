# RubyRabbitmq

The docker-compose file with RabbitMQ configuration.
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

You can access the RabbitMQ interface: `http://localhost:15672`.
Siging with credentials defined.

Get inside the consumer container:  
`docker exec -it ruby_rabbitmq_consumer bash`

Run the consumer:  
`ruby lib/app/consumer.rb`

Get inside the publisher container:  
`docker exec -it ruby_rabbitmq_publisher bash`

Run the publisher:  
`ruby lib/app/publisher.rb`