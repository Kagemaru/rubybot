require 'IRC'

SERVER	= "irc.rizon.net"
PORT	= 6667
CHANNEL	= "#idp"
NICK	= "rubytestbot"
PASS	= "mysticfire"
NAME	= "no one really"

$bot = IRC.new(NICK, SERVER, PORT, NAME)

def msg(target, message)
	$bot.send_message(target, message)
end
def act(target, action)
	$bot.send_action(target, action)
end
IRCEvent.add_callback('endofmotd') { |event|
	msg("NickServ","identify mysticfire")
	puts "identified!"
	$bot.add_channel(CHANNEL)
	puts "joined " + CHANNEL + "!"
}
IRCEvent.add_callback('join') { |event|
        if (event.from != NICK)
		msg(event.channel, "Hello #{event.from}!")
	end
}
IRCEvent.add_callback('privmsg') { |event|
	print event.from + ": " + event.message
	#if (event.message =~ /^!(\w+)(\W+w+)*/)
	if (event.message =~ /^!\S/)
		print "\t! matched."
		if (var[0] =~ /\./)
			options = var[0].split('.')
			count = 0
			output = ""
			options.each do |option|
				count += 1
				if count == 1 then next
				case option
					when 'name': output += "Name: "
					when 'time': output += "Date: "
					when 'info': output  = "Name:  Date: "
				end
				puts "sending quoteinfo: #{output}"
				msg(CHANNEL,output)
			end
		end
		var = event.message[1..-1].split
		case var[0]
			when 'say':
				print " saying: " + var[1..-1]
				msg(CHANNEL,var[1..-1])
			when 'do':
				print " doing: " + var[1..-1]
				act(CHANNEL,var[1..-1])
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
						print line.chomp
						msg(CHANNEL,line.chomp)
					end
				end
				file.close
		end
	end
	print "\n"
}

$bot.connect

