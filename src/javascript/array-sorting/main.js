/**
 * @return {number} - hashcode value.
 */
String.prototype.hashCode = function () {
    let hash = 0, i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
        chr = this.charCodeAt(i);
        hash = ((hash << 5) - hash) + chr;
        hash |= 0;
    }
    return hash;
};

/**
 * @param {number[]} a1 - First array (unsorted).
 * @param {number[]} a2 - Second array (unsorted).
 * @return {number[]} - Resulting array (sorted and merged).
 */
const intersection = function (a1, a2) {
    a1.sort((a, b) => a - b)
    a2.sort((a, b) => a - b)
    const intersections = []
    let l = 0, r = 0;
    while ((a2[l] && a1[r]) !== undefined) {
        const left = a1[r], right = a2[l];
        if (right === left) {
            intersections.push(right)
            while (left === a1[r]) r++;
            while (right === a2[l]) l++;
            continue;
        }
        if (right > left) while (left === a1[r]) r++;
        else while (right === a2[l]) l++;

    }
    return intersections;
};

/**
 * @param {Map<any, any>} args - benchmark's arguments.
 * @return {Map<any, any>} - array's hashcode.
 */
const main = function (args) {
    const output = new Map()
    const result = intersection(Array.from({length: args.get("array_size")}, () => Math.floor(Math.random() * args.get("array_size"))),
        Array.from({length: args.get("array_size")}, () => Math.floor(Math.random() * args.get("array_size"))));
    output.set("result", result.toString().hashCode())
    return output
}
