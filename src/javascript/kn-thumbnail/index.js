const sharp = require('sharp');
const fs = require('fs');
const http = require('http');
const url = require('url');

function thumbnail(input_url) {
  let iname = "img-" + (Math.random()).toString().substring(10) + ".png";
  const file = fs.createWriteStream(iname);
  let q = url.parse(input_url, true);
  var options = {
      host: q.hostname,
      path: q.path,
      port: q.port
  };
  http.get(options, function(response) {
      sharp_resizer = sharp().resize(100, 100).png();
      response.pipe(sharp_resizer).pipe(file);
      file.on("finish", () => {
          file.close();
      });
  });
  return iname
}

const handle = async (context, body) => {
  try {
    let url = body["url"];
    let res = thumbnail(url);
    return { "result": res }
  }
  catch(err) {
      return { "result": err } 
  }
}

// Export the function
module.exports = { handle };
