//import fetch from "node-fetch";

const thumbnail = function (imgUrl) {
    const fileName = "img-" + Date.now() + ".png"
    fetch(imgUrl)
        .then(function (res) {
            if (!res.ok) {
                throw new Error(`HTTP error! status: ${res.status}`);
            }
            return res.arrayBuffer();
        })
        .then(function (buf) {
            return new File([buf], fileName, {type: 'image/png'});
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

const main = async function (url) {
    console.log("2")
    const output = new Map()
    console.log("3")
    try {
        const resultArray = await Promise.all([thumbnail(url)])
    }
    catch(err) {
        console.log(err)
    }
    console.log("4")
    output.set("result", "ola")
    return output
};

console.log("1")
main("http://127.0.0.1:8000/snap.png");
