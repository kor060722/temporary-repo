function handler(event) {
    var request = event.request;
    var uri = request.uri;

    if (uri === '/index.html' || uri.startsWith('/images')) {
        return request;
    }

    return {
        statusCode: 302,
        statusDescription: 'Found',
        headers: {
            'location': { 'value': '/index.html' }
        }
    };
}
