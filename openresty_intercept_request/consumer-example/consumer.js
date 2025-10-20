/**
 * Example Kafka Consumer
 * 
 * This consumer reads failed requests from Kafka and can:
 * 1. Retry the requests to the backend
 * 2. Log them for analysis
 * 3. Store them in a database
 * 4. Send alerts
 */

const { Kafka } = require('kafkajs');
const axios = require('axios');

// Configuration
const KAFKA_BROKER = process.env.KAFKA_BROKER || 'localhost:29092';
const BACKEND_URL = process.env.BACKEND_URL || 'http://localhost:3000';
const CONSUMER_GROUP = process.env.CONSUMER_GROUP || 'failed-request-processor';
const RETRY_ENABLED = process.env.RETRY_ENABLED !== 'false'; // Default: true

// Initialize Kafka client
const kafka = new Kafka({
  clientId: 'failed-request-consumer',
  brokers: [KAFKA_BROKER],
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
});

const consumer = kafka.consumer({ groupId: CONSUMER_GROUP });

// Retry logic
async function retryRequest(failedRequest) {
  const { method, path, headers, body, query_string } = failedRequest;
  
  try {
    const url = `${BACKEND_URL}${path}${query_string ? '?' + query_string : ''}`;
    
    console.log(`🔄 Retrying request: ${method} ${url}`);
    
    const response = await axios({
      method: method.toLowerCase(),
      url: url,
      headers: headers,
      data: body ? body : undefined,
      timeout: 5000
    });
    
    console.log(`✅ Retry successful: ${method} ${path} - Status: ${response.status}`);
    return { success: true, status: response.status, data: response.data };
    
  } catch (error) {
    console.error(`❌ Retry failed: ${method} ${path} - Error: ${error.message}`);
    return { success: false, error: error.message };
  }
}

// Process message
async function processMessage(message) {
  try {
    const failedRequest = JSON.parse(message.value.toString());
    
    console.log('\n' + '='.repeat(80));
    console.log('📨 Received failed request:');
    console.log('='.repeat(80));
    console.log(`Timestamp: ${new Date(failedRequest.timestamp * 1000).toISOString()}`);
    console.log(`Method: ${failedRequest.method}`);
    console.log(`URI: ${failedRequest.uri}`);
    console.log(`Remote Address: ${failedRequest.remote_addr}`);
    console.log(`Error Reason: ${failedRequest.error_reason}`);
    console.log('Headers:', JSON.stringify(failedRequest.headers, null, 2));
    if (failedRequest.body) {
      console.log('Body:', failedRequest.body);
    }
    console.log('='.repeat(80));
    
    // Retry if enabled
    if (RETRY_ENABLED) {
      await new Promise(resolve => setTimeout(resolve, 2000)); // Wait 2s before retry
      const result = await retryRequest(failedRequest);
      
      if (result.success) {
        console.log('✨ Request successfully processed after retry');
      } else {
        console.log('⚠️  Request still failing, may need manual intervention');
        // Here you could:
        // - Store in database for later analysis
        // - Send alert/notification
        // - Move to dead letter queue
        // - Log to file
      }
    }
    
  } catch (error) {
    console.error('❌ Error processing message:', error.message);
    console.error(error);
  }
}

// Main function
async function run() {
  console.log('🚀 Starting Kafka Consumer...');
  console.log(`📡 Kafka Broker: ${KAFKA_BROKER}`);
  console.log(`🎯 Consumer Group: ${CONSUMER_GROUP}`);
  console.log(`🔄 Retry Enabled: ${RETRY_ENABLED}`);
  console.log(`🌐 Backend URL: ${BACKEND_URL}`);
  
  await consumer.connect();
  console.log('✅ Connected to Kafka');
  
  await consumer.subscribe({ 
    topic: 'failed-requests', 
    fromBeginning: true 
  });
  console.log('✅ Subscribed to topic: failed-requests');
  
  console.log('\n⏳ Waiting for messages...\n');
  
  await consumer.run({
    eachMessage: async ({ topic, partition, message }) => {
      await processMessage(message);
    },
  });
}

// Error handling
process.on('SIGTERM', async () => {
  console.log('\n👋 SIGTERM received, shutting down gracefully...');
  await consumer.disconnect();
  process.exit(0);
});

process.on('SIGINT', async () => {
  console.log('\n👋 SIGINT received, shutting down gracefully...');
  await consumer.disconnect();
  process.exit(0);
});

// Start consumer
run().catch(async (error) => {
  console.error('❌ Fatal error:', error);
  await consumer.disconnect();
  process.exit(1);
});

