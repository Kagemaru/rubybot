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
DEBUG   = true

#End of configuration

#Bot initialization
$bot = IRC.new(NICK, SERVER, PORT, NAME)

#End of initialization

#methods
def msg(target, message)
	print "\n\tSaying: '#{message}' to #{target}\n" if DEBUG
	$bot.send_message(target, message)
end
def act(target, action)
	print "\n\tsending action: '#{action}' to #{target}\n" if DEBUG
	$bot.send_action(target, action)
end
def join(channel)
	$bot.add_channel(channel)
	print "\n\tjoined channel: #{channel}" if DEBUG
end
def part(channel)
	$bot.part_channel(channel)
	print "\n\tleft channel: #{channel}" if DEBUG
end
def identify(pw)
	$bot.send_message("NICKSERV", "IDENTIFY #{pw}")
	print "\n\tidentified for #{NICK}!"	if DEBUG
end
def quit(message = "QUIT : Quit ordered by user") #later with server
	print "\n\tquit from server!\n"
	IRCConnection.send_to_server(message)
	IRCConnection.quit
end
#End of methods

#Event handlers. React on channel/user/serverevents

##Identify for the nick and let it join some channels after the MOTD
IRCEvent.add_callback('endofmotd') {
	join(CHANNEL) 
	identify("mysticfire")
}

##Greet users on join
IRCEvent.add_callback('join') { |event|
	msg(event.channel, "Hello #{event.from}!") unless (event.from == NICK)
}
##Reacts on channel/private messages
IRCEvent.add_callback('privmsg') { |event|
	print "\n#{event.from}: #{event.message}" if DEBUG
	##Checks if someone requests an action.
	if (event.message =~ /^[!?`]\S/)
		var = event.message[1..-1].split
		if (var[0] =~ /\S\./) #if there are options
			count = 0
			option = var[0].split('.')
			options.each { |opt| option[opt.intern] = true unless (count += 1) == 1 }
			var[0] = options[0] 
			options.delete
		end
		if (event.message =~ /^!\S/) #start of action section
			print "\t! matched.\n"
			case var[0]
				when 'say', 'do'
					if var[1] =~ /^#/ 
						$bot.channels.each { |channel|
							if channel.name == var[1]
								msg(var[1],var[2..-1].join(" ")) unless var[0] != 'say'
								act(var[1],var[2..-1].join(" ")) unless var[0] != 'do'
							end
						}
					else
						msg(event.channel,var[1..-1].join(" ")) unless event.channel == NICK || var[0] != 'say'
						act(event.channel,var[1..-1].join(" ")) unless event.channel == NICK || var[0] != 'do'
					end
				when 'quote':
					print "sending quote: "
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
			end #of action case
		elsif (event.message =~ /^\?\S/)	 #end of action section & start of information section
			print "\t? matched."
			case var[0]
				when 'debug'
					puts "1: #{event.stats[0]}"
					puts "2: #{event.stats[1]}"
					puts "3: #{event.stats[2]}"
					puts "4: #{event.stats[3]}"
					puts "*: #{event.channel}"
					puts $bot.channels
					$bot.channels.each { |ch| puts ch.name }
			end
		elsif (event.message =~ /^`\S/) #end of information section & start of system section
			print "\t` matched."
			case var[0]
				when 'quit'
					quit("quit order sent by: #{event.from}")
			end
		end
	end #of detecting triggers
}
#End of event handlers

$bot.connect
