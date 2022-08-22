import numpy as np


# Util methods.
def generate_array(array_size):
    return np.random.randint(1, array_size, array_size)


# Workload.
def intersect(nums1, nums2):
    res = []
    nums1.sort()
    nums2.sort()
    i = j = 0
    while i < len(nums1) and j < len(nums2):
        if nums1[i] > nums2[j]:
            j += 1
        elif nums1[i] < nums2[j]:
            i += 1
        else:
            if not (len(res) and nums1[i] == res[len(res) - 1]):
                res.append(nums1[i])
            i += 1
            j += 1

    return res


# Main function.
def main(args):
    return {"result": hash(tuple(intersect(generate_array(args['array_size']), generate_array(args['array_size']))))}
