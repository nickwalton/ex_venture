import Config

version = System.get_env("SHA") || "no sha"
config :ex_venture, version: String.trim(version)

config :ex_venture, Web.Endpoint,
  http: [port: 4000],
  server: true,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :ex_venture, :networking,
  port: 5555,
  server: true,
  socket_module: Networking.Protocol

config :ex_venture, :game,
  npc: Game.NPC,
  zone: Game.Zone,
  room: Game.Room,
  environment: Game.Environment.Implementation,
  shop: Game.Shop,
  zone: Game.Zone,
  continue_wait: 500

config :logger, level: :info
