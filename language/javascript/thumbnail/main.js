/**
 * @param {string} data - image's date to send.
 */
const sendRequest = function (data) {
    const xmlHttp = new XMLHttpRequest();
    xmlHttp.open("POST", "https://httpbin.org/anything", true);
    xmlHttp.send(data);
}

/**
 * @param {string} imgUrl - image url to fetch.
 * @return {string} - sent image filename.
 */
const thumbnail = function (imgUrl) {
    const fileName = "img-" + Date.now() + ".jpeg"
    fetch(imgUrl)
        .then(function (res) {
            if (!res.ok) {
                throw new Error(`HTTP error! status: ${res.status}`);
            }
            return res.arrayBuffer();
        })
        .then(function (buf) {
            return new File([buf], fileName, {type: 'image/jpeg'});
        })
        .then(function (res) {
            return res.text();
        })
        .then(function (res) {
            sendRequest(res)
        })
        .catch(e => {
            console.log("There has been a problem with your fetching image: " + e.message);
        });
    return fileName;
}

/**
 * @param {Map<any, any>} args - benchmark's arguments.
 * @return {Map<any, any>} - sent image filename.
 */
const main = async function (args) {
    const output = new Map()
    const resultArray = await Promise.all([thumbnail(args.get("img_url"))])
    output.set("result", resultArray[0])
    return output
}
