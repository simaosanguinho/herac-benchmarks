const mustache = require('mustache')
const http = require('http');
const url = require('url');

function random(b, e) {
    return Math.round(Math.random() * (e - b) + b);
}

const template = `<!DOCTYPE html>
	<html>
	  <head>
	    <title>Randomly generated data.</title>
	    <meta name="viewport" content="width=device-width, initial-scale=1.0">
	    <link href="http://netdna.bootstrapcdn.com/bootstrap/3.0.0/css/bootstrap.min.css" rel="stylesheet" media="screen">
	    <style type="text/css">
	      .container {
		              max-width: 500px;
		              padding-top: 100px;
		            }
    </style>
	  </head>
	  <body>
	    <div class="container">
	      <p>Welcome {{username}}!</p>
	      <p>Data generated at: {{cur_time}}!</p>
	      <p>Requested random numbers:</p>
	      <ul>
	        {{#random_numbers}}
        <li>{{.}}</li>
	        {{/random_numbers}}
      </ul>
	    </div>
	  </body>
	</html>`;

function get_request(template_url) {
    return new Promise((resolve, reject) => {
        let q = url.parse(template_url, true);
        var options = {
            host: q.hostname,
            path: q.path,
            port: q.port
        };
        http.get(options, function(response) {
            response.on('data', d => {
                resolve(d.toString('utf8'));
            });
            response.on('error', (error) => {
                reject(error);
            });
        });
    });
}

async function main(args) {
    let username = args['username'];
    let nsize = args['nsize'];
    var random_numbers = new Array(nsize);
    for(var i = 0; i < nsize; ++i) {
        random_numbers[i] = random(0, 100);
    }
    let template_args = { "cur_time": new Date().toLocaleString(), "username" : username, "random_numbers": random_numbers };
    return { "result": mustache.render(template, template_args) } 
}

exports.main = main;

/*
(async function () {
    console.log(await main({"url": "http://localhost:8000/template.html", "username": "rbruno", "nsize": 10}));
})();
*/
