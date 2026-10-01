extends RefCounted
## Presentation only. TreasuryGoals remains the authority for earned mods.
## Future entries must follow docs/mod-previews/DESIGN-STANDARD.md.
const PREVIEWS: Dictionary = {
	"burrowsteel": {"title":"BORE RUSH", "art":"res://assets/ui/mods/bore-rush-pappa-v1.png", "description":"Hold to drill forward. Steer your path. Release to stop."},
	"prismite": {"title":"LASER", "art":"res://assets/ui/mods/laser-pappa-v1.png", "description":"Toggle Laser, then hold Mine to cut a long, narrow tunnel."},
	"wallet_gold": {
		"title": "RESONANCE",
		"art": "res://assets/ui/mods/resonance-pappa-hammer-v1.png",
		"description": "Charge your drill in The Deep. Release a powerful mining wave."
	}
}

static func preview(resource: String) -> Dictionary:
	return PREVIEWS.get(resource, {})
