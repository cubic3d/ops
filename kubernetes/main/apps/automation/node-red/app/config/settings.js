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
        issuer: process.env.NODE_RED_OIDC_ISSUER,
        authorizationURL: process.env.NODE_RED_OIDC_ISSUER + "/authorization",
        tokenURL: process.env.NODE_RED_OIDC_ISSUER + "/token",
        userInfoURL: process.env.NODE_RED_OIDC_ISSUER + "/userinfo",
        clientID: process.env.NODE_RED_OIDC_CLIENT_ID,
        clientSecret: process.env.NODE_RED_OIDC_CLIENT_SECRET,
        callbackURL: "https://r." + "${domain}" + "/auth/strategy/callback",
        scope: ["email", "profile", "openid"],
        proxy: true,
        pkce: "S256",
        verify: function (issuer, profile, done) {
          done(null, profile);
        },
      },
    },
    users: [{ username: process.env.NODE_RED_USER, permissions: ["*"] }],
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
