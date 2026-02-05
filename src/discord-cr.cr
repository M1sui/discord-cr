require "http/client"
require "http/web_socket"
require "json"
require "openssl"

class DiscordBot
  alias MsgCb = Proc(String?, String, String, String, String?, Nil)

  def initialize(@tok : String, @int : Int32 = 33281)
    @seq = nil.as(Int64?)
    @hbms = 0
    @cb = nil.as(MsgCb?)
  end

  def on_msg(&blk : MsgCb)
    @cb = blk
  end

  def run
    ws = HTTP::WebSocket.new("wss://gateway.discord.gg/?v=10&encoding=json")

    ws.on_message do |txt|
      on_ws(ws, txt)
    end

    ws.on_close do |c, r|
      STDERR.puts "close #{c} #{r}"
      sleep 1.second
    end

    begin
      puts "Discord.cr is running...\n\n"
      ws.run
    rescue e
      STDERR.puts "exception #{e.class} #{e.message}"
      STDERR.puts e.backtrace.join("\n")
      sleep 1.second
    end
  end

  def send(gid : String | Nil, cid : String, txt : String)
    _ = gid
    url = URI.parse("https://discord.com/api/v10/channels/#{cid}/messages")
    hdr = HTTP::Headers{
      "Authorization" => "Bot #{@tok}",
      "Content-Type"  => "application/json",
      "User-Agent"    => "crystal-std/1",
    }
    bod = {"content" => txt}.to_json
    HTTP::Client.post(url, headers: hdr, body: bod)
  end

  private def on_ws(ws : HTTP::WebSocket, txt : String)
    js = JSON.parse(txt)
    op = js["op"].as_i
    if js.as_h.has_key?("s") && !js["s"].raw.nil?
      @seq = js["s"].as_i64
    end

    if op == 10
      @hbms = js["d"]["heartbeat_interval"].as_i
      spawn { hb(ws) }
      idn(ws)
      return
    end

    if op == 0
      t = js["t"].as_s
      if t == "MESSAGE_CREATE"
        msg(js["d"])
      end
    end
  end

  private def hb(ws : HTTP::WebSocket)
    loop do
      sleep @hbms.milliseconds
      dat = {"op" => 1, "d" => @seq}.to_json
      ws.send(dat)
    end
  end

  private def idn(ws : HTTP::WebSocket)
    dat = {
      "op" => 2,
      "d"  => {
        "token" => @tok,
        "intents" => @int,
        "properties" => {
          "os" => "linux",
          "browser" => "crystal",
          "device" => "crystal",
        },
      },
    }.to_json
    ws.send(dat)
  end

  private def msg(d : JSON::Any)
    if d["author"].as_h.has_key?("bot") && d["author"]["bot"].as_bool
      return
    end

    gid = d.as_h.has_key?("guild_id") ? d["guild_id"].as_s : nil
    cid = d["channel_id"].as_s
    txt = d["content"].as_s
    uid = d["author"]["id"].as_s

    nic = nil.as(String?)

    if d.as_h.has_key?("member") &&
      d["member"].as_h.has_key?("nick") &&
      !d["member"]["nick"].raw.nil?
      nic = d["member"]["nick"].as_s
    else
      nic = d["author"]["username"].as_s
    end

    if @cb
      @cb.not_nil!.call(gid, cid, txt, uid, nic)
    end
  end
end
