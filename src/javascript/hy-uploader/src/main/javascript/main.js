const main = async function (args) {
    const [downloadUrl, uploadUrl] = args.split(";", 2)
    const output = new Map()
    const res = polyHostAccess.downloadBytes(downloadUrl);
    polyHostAccess.uploadBytes(uploadUrl, res);
    output.set("result", res.length)
    return output
}
