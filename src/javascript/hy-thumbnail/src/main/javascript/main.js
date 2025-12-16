const main = async function (args) {
    const args_split = args.split(";");
    let url = args_split[0];
    let tmpDir = args_split[1];

    const output = new Map()
    let iname = tmpDir + "/img-thumbnail.png"
    let ratio = 0.25;
    polyHostAccess.writeBytes(polyHostAccess.resize(polyHostAccess.downloadBytes(url), ratio), iname);
    output.set("result", iname)
    return output
}
