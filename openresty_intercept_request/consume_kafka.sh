#!/bin/bash

# Colors
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${YELLOW}=== Kafka Consumer for Failed Requests ===${NC}\n"
echo "Consuming messages from topic: failed-requests"
echo "Press Ctrl+C to stop"
echo ""

docker-compose exec -T kafka kafka-console-consumer \
  --bootstrap-server localhost:9092 \
  --topic failed-requests \
  --from-beginning \
  --property print.timestamp=true \
  --property print.key=true \
  --formatter kafka.tools.DefaultMessageFormatter \
  --property print.value=true

