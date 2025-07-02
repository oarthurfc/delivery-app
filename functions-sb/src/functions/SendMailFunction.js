const { app } = require('@azure/functions');

app.serviceBusTopic('function-send-mail', {
    connection: 'sbdeliveryorderevents_SERVICEBUS',
    topicName: 'order.finished',
    subscriptionName: 'send-mail-subscriber',
    handler: (message, context) => {
        context.log('Service bus topic function processed message:', message);
    }
});
