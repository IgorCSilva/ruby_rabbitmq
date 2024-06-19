
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
