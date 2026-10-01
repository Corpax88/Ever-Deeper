extends RefCounted
## Presentation only. TreasuryGoals remains the authority for earned mods.
## Future entries must follow docs/mod-previews/DESIGN-STANDARD.md.
const PREVIEWS: Dictionary = {
	"wallet_gold": {
		"title": "RESONANCE",
		"art": "res://assets/ui/mods/resonance-pappa-hammer-v1.png",
		"description": "Charge your drill in The Deep. Release a powerful mining wave."
	}
}

static func preview(resource: String) -> Dictionary:
	return PREVIEWS.get(resource, {})
