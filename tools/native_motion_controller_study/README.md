# Native presentation boundary study

This is a source and recorded-evidence study based on `f34bf7486f560ba104c137009a5affe50d2a642b`.
It does not replace the production player, pilot consumer, assets, clocks or input.
The current pilot is not safe for arbitrary ordinary controls.

`presentation_contract.gd` keeps a copied final presentation request and a
separate ordered physical-event journal. It accepts externally verified original
draw records, validates the exact manifest sample and binds all recorded context,
including bridge samples and retained offsets, into a source ID. Requests never
replace that source until another draw acknowledgment arrives. A stale source,
equipment/bank change, turn, bridge interior or missing exact source phase remains
explicitly uncovered. It never chooses the nearest authored source bridge.

The ledger is deliberately not a clock or motion controller. A successful
state/heading lookup does not approve attack restarts, impact timing, speed,
offset release, event presentation, loading, pause or lifecycle behavior. Physical
events remain available in order, even when presentation requests are coalesced.
The caller must validate the supplied image hash against real captured bytes;
headless replay establishes no new rendered image or live post-draw integration.

`coverage_audit.py` enumerates every actual declared pose, including every bridge
interior, against all three ordinary states and four headings. It reports gaps
rather than generating an exponentially expanding transition bank. The current
schema-2 pilot cannot pass graph closure; expanding canonical phases alone does
not address interrupts of newly generated bridges.

The separate native source author owns poses, exporter, rig and art. A bounded
native 3D architecture trial may avoid raster graph growth, but camera/material
fidelity, contact/IK, mobile render cost and full ordinary input require separate
evidence. No such replacement is implemented here.
