require 'net/http'
require 'json'
require 'time'

class Buda
    #Name: getMarkets
    #Description: It returns every market in which buda operates
    #Return: Array
    def getMarkets()
        marketList = []
        budaMarketsURL = URI('https://www.buda.com/api/v2/markets.json')
        response=Net::HTTP.get(budaMarketsURL) 
        marketsJson = JSON.parse(response)
        markets=marketsJson['markets']
        for market in markets do
            marketList = Array(marketList).push(market['id'])
        end
        return marketList
    end
    #Name: tradesAux
    #Description: Auxiliar method for getTrades, it checks if the last date of the last entry is minnor or bigger than the actual time minus 24 hours.
    #             if its bigger than the actual time it call itself, otherwise it adds all the entries until it finds an entry older than 24 hours
    #Return: dictionary
    def tradesAux(market,pastTime,time,tradeDic)
        budaTradesURL = URI("https://www.buda.com/api/v2/markets/"+market+"/trades.json?timestamp="+time+"&limit=100")
        response=Net::HTTP.get(budaTradesURL) 
        tradesJson = JSON.parse(response)
        trades=tradesJson['trades']['entries']
        if trades[-1][0]>pastTime
            for trade in trades
                tradeDic[market]=Array(tradeDic[market]).push(trade)
            end
            self.tradesAux(market, pastTime, trades[-1][0], tradeDic)
        else
            for trade in trades
                if trade[0]>pastTime
                    tradeDic[market]=Array(tradeDic[market]).push(trade)
                end
            end
        end
        return tradeDic
    end
    #Name: getTrades
    #Description: It returns a dictionary with every entry of every market in the last 24 hours
    #Return: dictionary
    def getTrades(markets,pastTime, realTime)
        tradeDic={}
        for market in markets do
            tradeDic[market]=[]
            budaTradesURL = URI("https://www.buda.com/api/v2/markets/"+market+"/trades.json?timestamp="+realTime+"&limit=100")
            response=Net::HTTP.get(budaTradesURL) 
            tradesJson = JSON.parse(response)
            trades=tradesJson['trades']['entries']
            if trades[-1][0]>pastTime
                for trade in trades
                    tradeDic[market]=Array(tradeDic[market]).push(trade)
                end
                self.tradesAux(market, pastTime, trades[-1][0], tradeDic)
            else
                for trade in trades
                    if trade[0]>pastTime
                        tradeDic[market]=Array(tradeDic[market]).push(trade)
                    end
                end
            end
        end
        return tradeDic
    end
    #Name: getBiggest
    #Description: It returns a dictionary with the biggest ammount of every market in the last 24 hours
    #Return: dictionary
    def getBiggest(markets, pastTime, realTime)
        tradeDic = self.getTrades(markets, pastTime, realTime)
        for market in tradeDic
            name = market[0]
            entries = market[1]
            entries = entries.sort_by{|x| x[1].to_f}
            tradeDic[name]=entries[-1]
            
        end
        return tradeDic
    end  
end
class Timestamp
    #Name: getRealTime
    #Description: Return the actual time formatted as a valid input
    def getRealTime()
        time = Time.now.to_f.to_s.split('.')
        time= time[0]+time[1].slice(0,3)
        return time 
    end
    #Name: getRealTime
    #Description: Return the actual time minus 24 hours formatted as a valid input
    def getPastTime()
        time = (Time.now.to_f- 60 * 60 * 24).to_s.split('.')
        time= (time[0]+time[1].slice(0,3))
        return time 
    end
end
class Tabulate
    #Name: makeTable
    #Description: It prints the values of tradeDic as a table
    def makeTable(tradeDic)
        puts 'Mercado'+'  | '+'Moneda | '+'   Monto'
        puts ''
        for trade in tradeDic
            if trade[1]
                currency = trade[0].split('-')
                puts trade[0]+'  |  '+currency[0]+'   |  '+trade[1][1]
            else
                currency = trade[0].split('-')
                puts trade[0]+'  |  '+currency[0]+'   |  n/a'
            end 
        end
    end
end

buda = Buda.new
timestamp = Timestamp.new
table=Tabulate.new

budaMarkets = buda.getMarkets
realTime = timestamp.getRealTime
pastTime=timestamp.getPastTime
trades = buda.getBiggest(budaMarkets,pastTime,realTime)
table.makeTable(trades)
