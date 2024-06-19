
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