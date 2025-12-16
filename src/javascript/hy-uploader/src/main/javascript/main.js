const main = async function (url) {
    const output = new Map()
    const res = polyHostAccess.downloadBytes(url);
    polyHostAccess.uploadBytes(url, res);
    output.set("result", res.length)
    return output
}
