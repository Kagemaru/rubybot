require 'dbi' #MySQL layer
require 'rubygems'
require 'IRC'

#Configurations for the bot.
require 'config.rb'
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
def quit(message) #later with server
	if (!message) then message = "Quit ordered by user!"
	print "\n\tquit from server!\n"
	IRCConnection.send_to_server("QUIT :" + message)
	IRCConnection.quit
end
def mysql_query(query)
	print "\tSending query: #{query}" if DEBUG
	sql = DBI.connect("DBI:Mysql:kaminari:idp.ath.cx", "kaminari", "f4HSqTr9Yz3BAMnH")
	return sql.execute(query)
end
def mysql_count(table)
	print "\tGetting number of rows in #{table}"
	sql = DBI.connect("DBI:Mysql:kaminari:idp.ath.cx", "kaminari", "f4HSqTr9Yz3BAMnH")
	return sql.select_all("SELECT COUNT(*) FROM #{table};").to_s.to_i
end

#End of methods

#Event handlers. React on channel/user/serverevents

##Identify for the nick and let it join some channels after the MOTD
IRCEvent.add_callback('endofmotd') {
	join(CHANNEL) 
	identify(PASS)
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
		var[0].downcase!
		if (var[0] =~ /\S\./) #if there are options
			count = 0
			options = var[0].split('.')
			$option = {}
			options.each { |opt| $option[opt.intern] = true unless (count += 1) == 1 }
			var[0] = options[0] 
			options = nil
			$options = true
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
					quote = {}
					max = mysql_count("quotes") #fetch number of quotes in DB
					randnr = rand(max)
					puts "\n\tQuotes in DB = #{max}" if DEBUG
					res = mysql_query("SELECT * FROM quotes LIMIT #{randnr},1;")
					row = res.fetch_hash
					row.each { |key,value|
						if (key.to_s == 'uploader') then quote[key.intern] = value.intern
						elsif (key.to_s == 'about') && (value) then quote[key.intern] = value.split(":").intern
						else quote[key.intern] = value end
					}
					if $options
						output = ""
						output += "Uploader: #{quote[:uploader]} " if $option[:uploader] || $option[:info]
						output += "About: #{quote[:about].join(" ")}" if $option[:uploader] || $option[:info]
						output += "Date: #{quote[:date]}" if $option[:date] || $option[:info]
						print "sending info: #{output}\n"
						if event.channel != NICK then msg(event.channel, output)
						else msg(event.from, output) end
					end
                    msg(CHANNEL,randnr.to_s + ": " + quote[:quote])

=begin
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
=end
			end #of action case
		elsif (event.message =~ /^\?\S/)	 #end of action section & start of information section
			print "\t? matched."
			case var[0]
				when 'debug'
					puts
					puts "event.stats[1]: #{event.stats[0]} = nick"
					puts "event.stats[2]: #{event.stats[1]} = address"
					puts "event.stats[3]: #{event.stats[2]} = event"
					puts "event.stats[4]: #{event.stats[3]} = origin"
					puts "event.channel: #{event.channel}  = origin"
					puts
					puts "$bot.channels = #{$bot.channels}"
					$bot.channels.each { |ch| puts ch.name }
			end
		elsif (event.message =~ /^`\S/) #end of information section & start of system section
			print "\t` matched."
			case var[0]
				when 'quit'
					if event.stats[1] =~ /@his.dojo$/ then quit("quit order sent by: #{event.from}") 
					else msg(CHANNEL,"You're not authorized to do this. #{event.stats[1]}") end
				end
		end
	end #of detecting triggers
	print "\n"
}
#End of event handlers

$bot.connect
