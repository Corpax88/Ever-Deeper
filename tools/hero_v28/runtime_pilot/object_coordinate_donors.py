"""Offline merge of native donors whose only coordinate input is Object.

Keep original disconnected evaluated surfaces and their local vertex coordinates.
Clone qualifying shaders and replace Object coordinate reads with that attribute.
Generated, UV, authored attributes and every unsupported graph remain separate.
This is an opt-in bake experiment, not a change to native or production assets.
"""
from contextlib import contextmanager

import constant_donor_probe as probe

ATTRIBUTE = "native_donor_object_coordinates"
SOURCE_MATERIAL = "native_donor_source_material"
ALLOWED = {"OUTPUT_MATERIAL", "BSDF_PRINCIPLED", "TEX_COORD", "TEX_NOISE",
           "VALTORGB", "BUMP", "MAP_RANGE", "MATH", "SEPXYZ", "COMBXYZ",
           "VECT_MATH", "MIX_RGB", "MIX", "VALUE", "RGB"}


def material_audit(material):
    constant = probe.constant_material_audit(material)
    if constant["eligible"]:
        return dict(constant, coordinate_contract="constant")
    try:
        probe.opaque_material_audit(material)
    except ValueError as error:
        return {"eligible": False, "reason": str(error)}
    tree = material.node_tree
    output = next(n for n in tree.nodes if n.type == "OUTPUT_MATERIAL" and n.is_active_output)
    seen, pending, coordinate_nodes = set(), [output], []
    while pending:
        node = pending.pop()
        if node in seen:
            continue
        seen.add(node)
        if node.mute or node.type not in ALLOWED:
            return {"eligible": False, "reason": "Unsupported live node: " + node.type}
        if node.type == "TEX_COORD":
            used = [socket.name for socket in node.outputs if socket.is_linked]
            if node.object is not None or getattr(node, "from_instancer", False) or used != ["Object"]:
                return {"eligible": False, "reason": "Requires only native Object coordinates"}
            coordinate_nodes.append(node.name)
        if node.type == "TEX_NOISE" and not node.inputs["Vector"].is_linked:
            return {"eligible": False, "reason": "Implicit Generated coordinate remains separate"}
        for socket in node.inputs:
            for link in socket.links:
                if not link.is_valid or getattr(link, "is_muted", False):
                    return {"eligible": False, "reason": "Invalid/muted input link"}
                pending.append(link.from_node)
    if not coordinate_nodes:
        return {"eligible": False, "reason": "No supported Object-coordinate graph"}
    return {"eligible": True, "coordinate_contract": "evaluated_local_position_v1",
            "coordinate_nodes": sorted(coordinate_nodes),
            "live_node_types": sorted({node.type for node in seen})}


@contextmanager
def merged_donors(scene, sources):
    import bpy

    saved = [(source, source.hide_render) for source in sources]
    helper = None
    clones = []
    try:
        helper, stats = probe.create_merged_donor(
            scene, sources, material_checker=material_audit,
            object_coordinate_attribute=ATTRIBUTE)
        contracts = []
        for index, original in enumerate(list(helper.data.materials)):
            audit = material_audit(original)
            if not audit["eligible"]:
                raise ValueError("Material became ineligible: " + original.name)
            clone = original.copy()
            clones.append(clone)
            clone[SOURCE_MATERIAL] = original.name
            if audit["coordinate_contract"] != "constant":
                attribute = clone.node_tree.nodes.new("ShaderNodeAttribute")
                attribute.attribute_type = "GEOMETRY"
                attribute.attribute_name = ATTRIBUTE
                for name in audit["coordinate_nodes"]:
                    coordinate = clone.node_tree.nodes[name]
                    for link in list(coordinate.outputs["Object"].links):
                        clone.node_tree.links.new(attribute.outputs["Vector"], link.to_socket)
            helper.data.materials[index] = clone
            contracts.append({"material": original.name, "audit": audit})
        stats["coordinate_contract"] = "evaluated_local_position_v1"
        stats["attribute"] = ATTRIBUTE
        stats["materials"] = contracts
        for source, _ in saved:
            source.hide_render = True
        bpy.context.view_layer.update()
        yield helper, stats
    finally:
        for source, hidden in saved:
            source.hide_render = hidden
        if helper is not None:
            mesh = helper.data
            bpy.data.objects.remove(helper, do_unlink=True)
            bpy.data.meshes.remove(mesh)
        for material in clones:
            bpy.data.materials.remove(material)
        bpy.context.view_layer.update()
