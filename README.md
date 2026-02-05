# discord-cr

A simple framework for make DiscordBot in the Crystal language.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     discord-cr:
       github: your-github-user/discord-cr
   ```

2. Run `shards` or `shards install` 

## Usage

```crystal
require "discord-cr"

bot = DiscordBot.new("TOKEN")

bot.on_msg do |gid, cid, txt, uid, nic|
  if txt == "ping"
  bot.send(gid, cid, "pong!")
end

bot.run
```

Currently, only the message reception event and message transmission function are available. 


## Contributing

1. Fork it (<https://github.com/your-github-user/discord-cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [InstanceMethod](https://github.com/your-github-user) - creator and maintainer
