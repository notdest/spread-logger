-- utf-8 encoding, non-standard for windows

updateInterval  = 250 		-- время реакции цикла в main
writeInterval	= 60000		-- как часто пишем на диск
flushInterval	= 600000	-- как часто делаем перестраховочный flush

futures		= {	class 	= "SPBFUT",
				sec 	= "SRU0"
}

share		= {	class 	= "TQBR",
				sec 	= "SBER"
}

futuresOffer	= 0
futuresBid		= 0
shareOffer		= 0
shareBid		= 0

buffer1		 = "" 		-- использую два буфера в памяти, чтобы точно не насиловать диск частой записью
buffer2		 = ""
secondBuffer = false

f 		= nil
isRun 	= true

	function OnStop()
		isRun = false
		if secondBuffer then			-- Записываем буфер перед закрытием
			secondBuffer	= false
			f:write(buffer2)
			buffer2 = ""
		else
			secondBuffer	= true
			f:write(buffer1)
			buffer1 = ""
		end
		f:flush()
		f:close()
	end

	function OnInit( path )
		f = io.open(getScriptPath() .. os.date("\\%Y-%m-%d.csv"), "a")
	end



	function OnQuote(class, sec )
		local changed = false

		if     class == futures.class and sec == futures.sec then

			local quotes = getQuoteLevel2 ( futures.class , futures.sec)

			if math.floor(quotes.offer_count) ~= 0 and quotes.offer[1].price ~= futuresOffer then
				changed			= true
				futuresOffer	= quotes.offer[1].price
			end 

			if math.floor(quotes.bid_count) ~= 0 and quotes.bid[ math.floor(quotes.bid_count) ].price ~= futuresBid then
				changed			= true
				futuresBid 		= quotes.bid[ math.floor(quotes.bid_count) ].price
			end 
		elseif class == share.class   and sec == share.sec then

			local quotes = getQuoteLevel2 ( share.class , share.sec)


			if math.floor(quotes.offer_count) ~= 0 and quotes.offer[1].price ~= shareOffer then
				changed		= true
				shareOffer	= quotes.offer[1].price
			end 

			if math.floor(quotes.bid_count) ~= 0 and quotes.bid[ math.floor(quotes.bid_count) ].price ~= shareBid then
				changed		= true
				shareBid 	= quotes.bid[ math.floor(quotes.bid_count) ].price
			end 
		end

		if changed then
			local line = os.date("%X")..","..futuresOffer..","..futuresBid..","..shareOffer..","..shareBid .. "\n"
			if secondBuffer then
				buffer2 = buffer2 .. line
			else
				buffer1 = buffer1 .. line
			end
		end
	end


	function main()

		
		local lastWrite = 0
		local lastFlush = 0
		while isRun do
			if lastWrite >= writeInterval then
				lastWrite	= 0

				if secondBuffer then			-- отключаем буфер и записываем его
					secondBuffer	= false
					f:write(buffer2)
					buffer2 = ""
				else
					secondBuffer	= true
					f:write(buffer1)
					buffer1 = ""
				end
			end

			if lastFlush >= flushInterval then
				lastFlush	= 0
				f:flush()
			end

			lastFlush = lastFlush + updateInterval
			lastWrite = lastWrite + updateInterval
			sleep(updateInterval)
		end
	end