# Shiva

The FiveM framework engine for the Shiva ecosystem.

## File / Folder Structure

```text
shiva/
├── README.md
├── CLAUDE.md
├── GEMINI.md
├── AGENTS.md
├── compose.yml
├── bin/
│   └── update-fivem
├── fivem/
│   ├── README.md
│   └── resources/
│       ├── [gamemodes]/
│       │   ├── [maps]/
│       │   └── basic-gamemode/
│       ├── [gameplay]/
│       │   ├── [examples]/
│       │   ├── chat/
│       │   ├── chat-theme-gtao/
│       │   ├── player-data/
│       │   └── playernames/
│       ├── [managers]/
│       │   ├── mapmanager/
│       │   └── spawnmanager/
│       ├── [shiva-modules]/
│       │   ├── shiva-achievements/
│       │   ├── shiva-admin/
│       │   ├── shiva-ambulance/
│       │   ├── shiva-banking/
│       │   ├── shiva-business/
│       │   ├── shiva-crime/
│       │   ├── shiva-housing/
│       │   ├── shiva-inventory/
│       │   ├── shiva-phone/
│       │   ├── shiva-police/
│       │   └── ...many additional Shiva feature modules
│       ├── [shiva-overrides]/
│       ├── [shiva]/
│       │   ├── shiva-boot/
│       │   ├── shiva-core/
│       │   ├── shiva-db/
│       │   └── shiva-fw/
│       ├── [standalone]/
│       │   ├── oxmysql/
│       │   └── PolyZone/
│       ├── [system]/
│       └── [test]/
├── runtimes/
│   └── alpine-3/
│       ├── Dockerfile
|       └── server.cfg.stub
│       └── entrypoint.sh
└── txData/
```

> `fivem/resources/[shiva-modules]/` contains the bulk of the gameplay systems, while `fivem/resources/[shiva]/` contains the core framework resources.

# Related Repositories:

Below are some related repositories that complement the functionality of the Shiva Client:

- https://github.com/adrianmejias/shiva-core
- https://github.com/adrianmejias/shiva-modules
- https://github.com/adrianmejias/shiva-fw
- https://github.com/adrianmejias/shiva (this repo)
- https://github.com/adrianmejias/shiva-db
- https://github.com/adrianmejias/shiva-cli
- https://github.com/adrianmejias/shiva-boot
- https://github.com/adrianmejias/shiva-test
- https://github.com/adrianmejias/shiva-docs
- https://github.com/adrianmejias/shiva-api
- https://github.com/adrianmejias/shiva-panel
