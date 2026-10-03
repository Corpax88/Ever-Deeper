extends RefCounted
## Presentation only. TreasuryGoals remains the authority for earned mods.
## Future entries must follow docs/mod-previews/DESIGN-STANDARD.md.
const PREVIEWS: Dictionary = {
	"singularity": {"title":"VORTEX", "art":"res://assets/ui/mods/vortex-pappa-v1.png", "description":"Loose resources catch up while you move and mine."},
	"deep_alloy": {"title":"COREBREAKER", "art":"res://assets/ui/mods/corebreaker-pappa-v1.png", "description":"Mine to charge. Strike one ore node up to three times."},
	"phasecrystal": {"title":"RICOCHET", "art":"res://assets/ui/mods/ricochet-pappa-v1.png", "description":"Fire a drill that bounces between exposed rock faces."},
	"echo_crystal": {"title":"CHAINBREAKER", "art":"res://assets/ui/mods/chainbreaker-pappa-v1.png", "description":"Hit rock or ore to chain through ALL visible rock edges and exposed ore nodes."},
	"rootiron": {"title":"TWIN AUGER", "art":"res://assets/ui/mods/twin_auger-pappa-v1.png", "description":"Two side augers widen each rock hit. Hold Mine and steer."},
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
