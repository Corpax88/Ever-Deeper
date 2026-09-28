/* Scoped DEV15.16 position-message cadence control. Audio graph is untouched. */
(() => {
  let enabled = globalThis.FPS_FIX_AUDIO_START_ENABLED !== false;
  let serial = 0;
  let version = 0;
  let positionMessages = 0;
  let configurationsSent = 0;
  let configurationsReceived = 0;
  let stalePositionMessages = 0;
  const nodes = new Map();
  function configure(node, state) {
    state.hz = enabled && state.music ? 60 : 0;
    state.version = ++version;
    configurationsSent++;
    node.port.postMessage({ type: 'fps-fix-reporting', hz: state.hz, version: state.version });
  }
  globalThis.FPS_FIX_AUDIO = Object.freeze({
    setEnabled(value) {
      enabled = Boolean(value);
      for (const [node, state] of nodes) configure(node, state);
      return this.snapshot();
    },
    snapshot() {
      return {
        enabled, cadenceHz: 60, active: nodes.size, positionMessages,
        configurationsSent, configurationsReceived, stalePositionMessages,
        nodes: Array.from(nodes.values(), state => ({ ...state })),
      };
    },
    attach(node, music) {
      const state = {
        id: ++serial, music: Boolean(music), hz: 0, version: 0,
        confirmedVersion: 0, receivedHz: null, positionMessages: 0,
        lastSamplePosition: null,
      };
      nodes.set(node, state);
      configure(node, state);
    },
    detach(node) { nodes.delete(node); },
    observe(node, message) {
      const state = nodes.get(node);
      if (!state) return false;
      if (message.type === 'position') {
        positionMessages++;
        state.positionMessages++;
        if (message.fpsFixVersion !== state.version) {
          stalePositionMessages++;
          return false;
        }
        state.lastSamplePosition = message.data;
      } else if (message.type === 'fps-fix-configured') {
        configurationsReceived++;
        if (message.version === state.version) {
          state.confirmedVersion = message.version;
          state.receivedHz = message.hz;
        }
      }
      return true;
    },
  });
})();
