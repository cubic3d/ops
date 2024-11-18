module.exports = {
  flowFile: 'flows.json',
  credentialSecret: process.env.NODE_RED_CREDENTIAL_SECRET,
  flowFilePretty: true,

  uiPort: process.env.PORT || 1880,

  diagnostics: {
    enabled: true,
    ui: true,
  },

  runtimeState: {
    enabled: false,
    ui: false,
  },

  logging: {
    console: {
      level: "info",
      metrics: false,
      audit: false,
    },
  },

  contextStorage: {
    default: { module: "localfilesystem" },
    memory: { module: "memory" },
  },

  exportGlobalContextKeys: false,

  externalModules: {
  },

  editorTheme: {
    palette: {
    },

    projects: {
      enabled: false,
      workflow: {
        mode: "manual",
      },
    },

    codeEditor: {
      lib: "monaco",
      options: {
      },
    },

    markdownEditor: {
      mermaid: {
        enabled: true,
      },
    },

    multiplayer: {
      enabled: false,
    },
  },

  functionExternalModules: true,
  functionTimeout: 0,
  functionGlobalContext: {
  },

  debugMaxLength: 1000,

  mqttReconnectTime: 15000,
  serialReconnectTime: 15000,
}
