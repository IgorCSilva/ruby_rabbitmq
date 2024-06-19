
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