const main = async function (url) {
    const output = new Map()
    let iname = "img-" + (Math.random()).toString().substring(10) + ".png"
    let ratio = 0.25;
    jsHostAccess.writeBytes(jsHostAccess.resize(jsHostAccess.downloadBytes(url), ratio), iname);
    output.set("result", iname)
    return output
}
