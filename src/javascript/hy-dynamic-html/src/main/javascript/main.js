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

const main = async function (args) {
    const output = new Map();
    const args_split = args.split(";");
    let url = args_split[0];
    let username = args_split[1];
    let nsize = args_split[2];
    var random_numbers = new Array(nsize);
    for(var i = 0; i < nsize; ++i) {
        random_numbers[i] = random(0, 100);
    }
    let template_args = "{ \"cur_time\": \"" + new Date().toLocaleString() + "\", \"username\" : \"" + username  + "\", \"random_numbers\": [" + random_numbers + "]}";
    output.set("result", polyHostAccess.mustache(template, template_args));
    return output;
}
