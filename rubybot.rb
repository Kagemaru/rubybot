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
def notice(target,notice)
	print "\n\tSending the NOTICE: '#{notice}' to #{target}\n" if DEBUG
	$bot.send_notice(target, notice)
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
	if (!message) then message = "Quit ordered by user!" end
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

def quote_info(quote)
	output = ""
	$option.each {
		|key,value|
		if $option[key] || $option[:info]
			output += key.to_s.capitalize + ": "
			if quote[key].is_a?(Hash) || quote[key].is_a?(Array)
				output += quote[key].join(", ") + " "
			elsif quote[key]
				output += quote[key].to_s + " "
			else
				output += "- "
			end
		end
	}
	return output
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
			options.each { 
				|opt|
				if opt == "info"
					$option[:uploader] = $option[:about] = $option[:date] = true
				else
					$option[opt.intern] = true unless (count += 1) == 1
				end
			}
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
					puts "\n\tQuotes in DB = #{max} and randnr = #{randnr}" if DEBUG
					puts "\n\tvar[1] = #{var[1]} is set? #{(var[1]?true:false)}  and is Integer? #{var[1].to_i.is_a?(Integer)}" if DEBUG
					if var[1] && var[1].to_i.is_a?(Integer) && var[1].to_i <= max
						puts "\n\tFetching Quote #{var[1]}" if DEBUG
						res = mysql_query("SELECT * FROM quotes LIMIT #{var[1].to_i - 1},1;")
					else
						puts "\n\tFetching random Quote" if DEBUG
						res = mysql_query("SELECT * FROM quotes LIMIT #{randnr},1;")
					end
					row = res.fetch_hash
					row.each { |key,value|
						if (key.to_s == 'uploader') then quote[key.intern] = value.intern
						elsif (key.to_s == 'about') && (value) then quote[key.intern] = value.split(";").each { |value| value.intern }
						else quote[key.intern] = value end
					}
					if $options
=begin
						output = ""
						if $option[:uploader] || $option[:info]
							output += "Uploader: "
							if quote[:uploader]
								output += quote[:uploader] + " "
							else
								output += "- "
							end
						end
						if $option[:about] || $option[:info] 
							output += "About: "
							if quote[:about]
								output += quote[:about].join(" ") + " "
							else
								output += "- "
							end
						end
						if $option[:date] || $option[:info]
							output += "Date: "
							if quote[:date]
								output += quote[:date] + " " 
							else
								output += "- "
							end
=end
						output = quote_info(quote)
						print "\n\tsending info: #{output}\n"
						if event.channel != NICK then msg(event.channel, output)
						else msg(event.from, output) end
					end
                    msg(CHANNEL,quote[:id].to_s + ": " + quote[:quote])

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
				when 'roll'
					dice = {}
					if $options
						if $option[:secret] || $option[:s]
							dice[:mtype] = "notice"
						elsif $option[:private] || $option[:p] || $option [:pm]
							dice[:mtype] = "pm"
						elsif $option[:detail] || $option[:d]
							dice[:detail] = true
						end	
					end	
					if var[1] =~ /(\d*)d(\d+)($|\+\d+|-\d+)/
						puts var[1]+ " is a valid die roll of #{$1}d#{$2}#{$3}" if DEBUG
						puts dice.inspect if DEBUG
						dice[:times]  = ($1 ? $1.to_i : 1)
						dice[:die]    = $2.to_i
						dice[:mod]    = ($3 ? $3.to_i : 0)
						dice[:result] = 0
						dice[:rolls]  = []
						for i in 1..dice[:times] do
							dice[:rolls][i-1] = (rand(dice[:die])+1)
							dice[:result] += dice[:rolls][i-1] 
							puts "\n\tRoll #{i}: #{dice[:rolls][i-1]}. Total: #{dice[:result]}."
						end
						dice[:result] += dice[:mod]
						if dice[:detail]
							dice[:msg]  = "#{event.stats[0]} rolled #{var[1]}. "
							dice[:msg] += "Result: #{dice[:rolls].join(" + ")} "
							dice[:msg] += "(#{(dice[:mod] < 0)?dice[:mod].to_s: "+" + dice[:mod].to_s}) "
							dice[:msg] += "= #{dice[:result]}."
						else
							dice[:msg] = "#{event.stats[0]} rolled #{var[1]}. Result: #{dice[:result]}."
						end
						if dice[:mtype] == "pm"
							msg(event.stats[0],dice[:msg])
						elsif dice[:mtype] == "notice"
							notice(event.stats[0],dice[:msg])
						elsif event.stats[2] == "PRIVMSG"
							msg(event.stats[0],dice[:msg])
						else
							msg(event.channel,dice[:msg])
						end

					end
			end #of action case
		elsif (event.message =~ /^\?\S/)	 #end of action section & start of information section
			print "\t? matched."
			case var[0]
				when 'debug'
					puts
					puts "event.stats[0]: #{event.stats[0]} = nick"
					puts "event.stats[1]: #{event.stats[1]} = address"
					puts "event.stats[2]: #{event.stats[2]} = event"
					puts "event.stats[3]: #{event.stats[3]} = origin"
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
