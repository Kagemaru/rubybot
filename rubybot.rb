require 'IRC'

#Configurations for the bot.
#ToDo: Move to a seperate file.
#ToDo: Make it less static (multiple channels, multiple nicks... maybe even multiple servers?)

SERVER	= "idp.ath.cx"
PORT	= 6667
CHANNEL	= "#idp"
NICK	= "rubybot"
PASS	= "mysticfire"
NAME	= "no one really"

#End of configuration

#Bot initialization
$bot = IRC.new(NICK, SERVER, PORT, NAME)

#End of initialization

#methods
def msg(target, message)
	$bot.send_message(target, message)
end
def act(target, action)
	$bot.send_action(target, action)
end
#End of methods

#Event handlers. React on channel/user/serverevents

##Identify for the nick and let it join some channels after the MOTD
IRCEvent.add_callback('endofmotd') { |event|
	#msg("NickServ","identify mysticfire")
	#puts "identified!"
	$bot.add_channel(CHANNEL)
	puts "joined " + CHANNEL + "!"
}

##Greet users on join
IRCEvent.add_callback('join') { |event| msg(event.channel, "Hello #{event.from}!") unless (event.from == NICK) }
##Reacts on channel/private messages
IRCEvent.add_callback('privmsg') { |event|
	puts "#{event.from}: #{event.message}"
	#if (event.message =~ /^!(\w+)(\W+w+)*/)
	if (event.message =~ /^!\S/)
		print "\t! matched."
		var = event.message[1..-1].split
		if (var[0] =~ /\./)
			options = var[0].split('.')
			count = 0
			output = ""
			options.each do |option|
				count += 1
				if count == 1 then
					next
				end
				case option
					when 'name'
						output += "Name: "
					when 'time'
						output += "Date: "
					when 'info'
						output  = "Name:  Date: "
				end
				puts "sending quoteinfo: #{output}"
				msg(CHANNEL,output)
			end
		end
		var = event.message[1..-1].split
		case var[0]
			when 'methodinfo':
				puts "1: #{event.stats[0]}"
				puts "2: #{event.stats[1]}"
				puts "3: #{event.stats[2]}"
				puts "4: #{event.stats[3]}"
				puts "*: #{event.channel}"
				puts $bot.channels
				$bot.channels.each { |ch| puts ch.name }
			when 'say':
				if var[1] =~ /^#/ 
					$bot.channels.each { |channel|
						if channel.name == var[1]
							print " saying: #{var[2..-1].join(" ")} on channel: #{var[1]}\n"
							msg(var[1],var[2..-1].to_s.join(" "))
						end
					}
				else
					print " saying: #{ var[1..-1].join(" ")}\n"
					msg(event.channel,var[1..-1].join(" "))
				end
			when 'do':
				print " doing: #{var[1..-1].join(" ")}\n"
				act(event.channel,var[1..-1].join(" "))
			when 'quote':
				print " sending quote: "
				file = File.open('quotes.txt')
				file.max
				count = 0
				if (var[1].to_i > 0) && (var[1].to_i <= file.lineno) then number = var[1].to_i
				else number = (rand(file.lineno) + 1)
				end				
				file.rewind
				file.each_line do |line|
					if ((count += 1) == number)
						print line.chomp + "\n"
						msg(CHANNEL,line.chomp)
					end
				end
				file.close
		end
	end
}
#End of event handlers

$bot.connect
