require 'twilio-ruby'
require 'rufus-scheduler'
require 'httparty'

# Set up a client to talk to the Twilio REST API.
account_sid = 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX' # Your Account SID from www.twilio.com/console
auth_token = 'YYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY' # Your Auth Token from www.twilio.com/console
@client = Twilio::REST::Client.new account_sid, auth_token

# Set up our scheduler.
scheduler = Rufus::Scheduler.new

def get_quote
  r = HTTParty.get('https://morbotron.com/api/random')
  # Check if our request had a valid response.
  if r.code == 200
      json = r.parsed_response
      # Extract the episode number and timestamp from the API response.
      _, episode, timestamp = json["Frame"].values

      # Build a proper URL 
      image_url = "https://morbotron.com/meme/" + episode + "/" + timestamp.to_s
      
      # Combine each line of subtitles into one string, seperated by newlines.
      caption = json["Subtitles"].map{|subtitle| subtitle["Content"]}.join("\n")

      return image_url, caption
  end
end

def send_MMS
  media, body = get_quote
  begin
    @client.messages.create(
      body: body,
      media_url: media,
      to: '+12345678901',  # Replace with your phone number
      from: '+12345678901' # Replace with your Twilio number
    )
    puts "Message sent!"
  rescue TwilioRestException
    # If an error occurs, print it out.
    $stderr.print "Message failed to send: " + $!
  end
end

scheduler.every '24h' do
  send_MMS
end
scheduler.join