const main = async function (url) {
    const output = new Map()
    jsHostAccess.uploadBytes(url, jsHostAccess.downloadBytes(url));
    output.set("result", url)
    return output
}
