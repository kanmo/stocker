# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

config :stocker, master_node: :'master@127.0.0.1'

config :stocker, slave_nodes: [:'slave1@127.0.0.1',
                              :'slave2@127.0.0.1',
                              :'slave3@127.0.0.1']
