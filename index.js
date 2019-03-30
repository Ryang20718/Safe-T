var request = require('request');

var headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $(gcloud auth application-default print-access-token)'
};

var dataString = '@request.json';

var options = {
    url: 'https://automl.googleapis.com/v1beta1/projects/cs131-1552025416924/locations/us-central1/models/ICN6390988586782325408:predict',
    method: 'POST',
    headers: headers,
    body: dataString
};

function callback(error, response, body) {
    if (!error && response.statusCode == 200) {
        console.log(body);
    }
}

request(options, callback);

