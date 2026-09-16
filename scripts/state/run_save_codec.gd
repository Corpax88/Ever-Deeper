extends RefCounted
## One on-disk format. The dictionary API stays in RunState; no Objects are
## decoded. Fixed header and SHA-256 are checked before Variant decoding.

const SCHEMA_ID: String = "ever_deeper_run_state"
const SCHEMA_VERSION: int = 3
const MAGIC: int = 0x52445645 # EVDR in little-endian byte order.
const HEADER_BYTES: int = 44 # magic, schema, payload length, 32-byte SHA-256.
const MAX_PAYLOAD_BYTES: int = 64 * 1024 * 1024


static func encode(document: Dictionary) -> PackedByteArray:
	var payload: PackedByteArray = var_to_bytes(document)
	if payload.size() < 8 or payload.size() > MAX_PAYLOAD_BYTES:
		return PackedByteArray()
	var encoded: PackedByteArray = PackedByteArray()
	encoded.resize(12)
	encoded.encode_u32(0, MAGIC)
	encoded.encode_u32(4, SCHEMA_VERSION)
	encoded.encode_u32(8, payload.size())
	encoded.append_array(_digest(payload))
	encoded.append_array(payload)
	return encoded


static func decode(encoded: PackedByteArray) -> Variant:
	if encoded.size() < HEADER_BYTES:
		return null
	if encoded.decode_u32(0) != MAGIC:
		return {"schema": "", "version": 0}
	var version: int = encoded.decode_u32(4)
	if version != SCHEMA_VERSION:
		return {"schema": SCHEMA_ID, "version": version}
	var payload_size: int = encoded.decode_u32(8)
	if payload_size < 8 or payload_size > MAX_PAYLOAD_BYTES or encoded.size() != HEADER_BYTES + payload_size:
		return null
	var payload: PackedByteArray = encoded.slice(HEADER_BYTES)
	if _digest(payload) != encoded.slice(12, HEADER_BYTES):
		return null
	# One native size check validates the complete value, with Objects refused.
	# It also rejects trailing data inside an otherwise well-formed payload.
	if payload.decode_var_size(0, false) != payload_size:
		return null
	var document: Variant = bytes_to_var(payload)
	return document if document is Dictionary else null


static func _digest(payload: PackedByteArray) -> PackedByteArray:
	var hashing: HashingContext = HashingContext.new()
	hashing.start(HashingContext.HASH_SHA256)
	hashing.update(payload)
	return hashing.finish()
