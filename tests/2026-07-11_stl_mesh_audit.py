#!/usr/bin/env python3

import argparse
import collections
import json
import math
import struct
import sys
from pathlib import Path


QUANTUM = 1e-6


def parse_binary_stl(data):
    if len(data) < 84:
        return None

    triangle_count = struct.unpack_from("<I", data, 80)[0]
    if len(data) != 84 + triangle_count * 50:
        return None

    triangles = []
    offset = 84
    for _ in range(triangle_count):
        values = struct.unpack_from("<12fH", data, offset)
        triangles.append(
            (
                values[3:6],
                values[6:9],
                values[9:12],
            )
        )
        offset += 50
    return triangles


def parse_ascii_stl(data):
    triangles = []
    triangle = []
    for raw_line in data.decode("utf-8").splitlines():
        fields = raw_line.split()
        if fields[:1] != ["vertex"]:
            continue
        triangle.append(tuple(float(value) for value in fields[1:4]))
        if len(triangle) == 3:
            triangles.append(tuple(triangle))
            triangle = []

    if triangle or not triangles:
        raise ValueError("ASCII STL has incomplete or missing triangles")
    return triangles


def parse_stl(path):
    data = path.read_bytes()
    triangles = parse_binary_stl(data)
    return triangles if triangles is not None else parse_ascii_stl(data)


def quantize(vertex):
    return tuple(int(round(value / QUANTUM)) for value in vertex)


def signed_tetrahedron_volume(triangle):
    first, second, third = triangle
    cross = (
        second[1] * third[2] - second[2] * third[1],
        second[2] * third[0] - second[0] * third[2],
        second[0] * third[1] - second[1] * third[0],
    )
    return (
        first[0] * cross[0]
        + first[1] * cross[1]
        + first[2] * cross[2]
    ) / 6.0


def audit(triangles):
    parent = list(range(len(triangles)))

    def find(item):
        while parent[item] != item:
            parent[item] = parent[parent[item]]
            item = parent[item]
        return item

    def union(left, right):
        left_root = find(left)
        right_root = find(right)
        if left_root != right_root:
            parent[right_root] = left_root

    edge_owner = {}
    edge_incidence = collections.Counter()
    volume = 0.0

    for triangle_index, triangle in enumerate(triangles):
        vertices = tuple(quantize(vertex) for vertex in triangle)
        volume += signed_tetrahedron_volume(triangle)
        for start, end in ((0, 1), (1, 2), (2, 0)):
            edge = tuple(sorted((vertices[start], vertices[end])))
            edge_incidence[edge] += 1
            if edge in edge_owner:
                union(triangle_index, edge_owner[edge])
            else:
                edge_owner[edge] = triangle_index

    invalid_edges = sum(
        incidence != 2 for incidence in edge_incidence.values()
    )
    components = len({find(index) for index in range(len(triangles))})
    return {
        "triangles": len(triangles),
        "components": components,
        "invalid_edges": invalid_edges,
        "volume_mm3": volume,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("path", type=Path)
    component_group = parser.add_mutually_exclusive_group()
    component_group.add_argument("--expected-components", type=int, default=1)
    component_group.add_argument(
        "--expected-components-any",
        action="store_true",
    )
    args = parser.parse_args()

    try:
        result = audit(parse_stl(args.path))
    except (OSError, ValueError, UnicodeDecodeError, struct.error) as error:
        print(json.dumps({"path": str(args.path), "error": str(error)}))
        return 1

    result["path"] = str(args.path)
    print(json.dumps(result, sort_keys=True))

    valid_components = (
        args.expected_components_any
        or result["components"] == args.expected_components
    )
    valid = (
        valid_components
        and result["invalid_edges"] == 0
        and math.isfinite(result["volume_mm3"])
        and result["volume_mm3"] > 0
    )
    return 0 if valid else 1


if __name__ == "__main__":
    sys.exit(main())
