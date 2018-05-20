require 'yaml'
require 'net/ping'
require 'line/bot'
require 'google_drive'

# RollCall
class RollCall
  def initialize
    @config = YAML.load_file('config.yml')

    @line_client = Line::Bot::Client.new do |config|
      config.channel_secret = @config['line']['channel_secret']
      config.channel_token  = @config['line']['channel_token']
    end
  end

  def exec
    exists = []
    @config['devices'].each do |elm|
      if Net::Ping::External.new(elm['ip']).ping?
        puts "#{elm['name']} is reachable."
        # push_line("#{elm['name']} is reachable.")
        exists << 1
      else
        puts "#{elm['name']} is unreachable."
        # push_line("#{elm['name']} is unreachable.")
        exists << 0
      end
    end
    push_spreadsheet(exists)
  end

  private

  def push_line(text)
    message = {
      type: 'text',
      text: text
    }

    res = @line_client.push_message(@config['line']['user_id'], message)
    p res.class unless res.is_a?(Net::HTTPSuccess)
  end

  def push_spreadsheet(exists)
    session = GoogleDrive::Session.from_config('config.json')

    ws = session
         .spreadsheet_by_key(@config['spreadsheet']['key'])
         .worksheets[0]

    row = ws.num_rows + 1
    col = 1

    ws[row, col] = Time.now.strftime('%Y/%m/%d %H:%M')
    col += 1
    exists.each do |elm|
      ws[row, col] = elm
      col += 1
    end
    ws.save
  end
end

roll_call = RollCall.new
roll_call.exec
