module.exports = {
  flowFile: 'flows.json',
  credentialSecret: process.env.NODE_RED_CREDENTIAL_SECRET,
  flowFilePretty: true,

  adminAuth: {
    type: "strategy",
    strategy: {
      name: "openidconnect",
      autoLogin: true,
      label: "Sign in",
      icon: "fa-cloud",
      strategy: require("passport-openidconnect").Strategy,
      options: {
        issuer: "https://auth.${domain}",
        authorizationURL: "https://auth.${domain}/api/oidc/authorization",
        tokenURL: "https://auth.${domain}/api/oidc/token",
        userInfoURL: "https://auth.${domain}/api/oidc/userinfo",
        clientID: "node-red",
        clientSecret: process.env.NODE_RED_OIDC_CLIENT_SECRET,
        callbackURL: "https://r.${domain}/auth/strategy/callback",
        scope: ["openid", "email", "profile", "groups"],
        proxy: true,
        verify: function (issuer, profile, done) {
          done(null, profile);
        },
      },
    },
    users: [{ username: "cubic", permissions: ["*"] }],
  },

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
