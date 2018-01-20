defmodule MasterClient do

  def getPID do
      :global.whereis_name(Client.getServerName())
  end

  def init({:ok, serverIP, numClients, totalClients}) do
    stateMap = %{
                 regClients: 0,
                 subClients: 0
              }
      IO.inspect self(), label: "In master Client"
      IO.inspect "*******************************"
      serverPID = getPID()
      MasterClient.setupNodes(numClients, Client, totalClients, self())
      {:ok, [serverPID, totalClients, stateMap]}
  end

  def handle_cast({:ackRegister, bool, clientPID, totalClients, password}, state) do
    state =
      if bool == true do
        stateMap = List.last(state)
        regClients = Map.get(stateMap, :regClients)
        regClients = regClients + 1
        if regClients != totalClients do
          stateMap = Map.put(stateMap, :regClients, regClients)
          List.replace_at(state, -1, stateMap)
        else
          # IO.puts "All Clients registered"
          initialSubscribe(0, totalClients, password)
          state
        end
      else
        IO.inspect clientPID, label: "not registered"
      end
    {:noreply, state}
  end

  def handle_cast({:ackSubscribe, clientPID, totalClients, password, serverPID}, state) do
    subMap = List.last(state)
    subClients = Map.get(subMap, :subClients)
    if subClients != totalClients do
      subClients = subClients + 1
      subMap = Map.put(subMap, :subClients, subClients)
      state = List.replace_at(state, -1, subMap)
      if subClients == totalClients do
         # :timer.sleep(1000)
         # GenServer.cast(serverPID, {:print})
         # IO.inspect "All users have finished subscribing"
         wordsNo = Enum.random(3..8)
         initialAction(0, totalClients, password, wordsNo)
      end
    else
      IO.puts "All Clients have already subscribed"
    end
    {:noreply, state}
  end

  def setupNodes(clientNo, module, totalClients, masterClientPID) when clientNo <= 1 do
    {:ok, clientPID} = GenServer.start_link(module, {:ok, clientNo, totalClients, masterClientPID}, name: :"actor#{clientNo}")
  end

  def setupNodes(clientNo, module, totalClients, masterClientPID) do
    {:ok, clientPID} = GenServer.start_link(module, {:ok, clientNo, totalClients, masterClientPID}, name: :"actor#{clientNo}")
    setupNodes(clientNo-1, module, totalClients, masterClientPID)
  end

  def initialSubscribe(curClient, totalClients, password) do
    if curClient == totalClients do
      # IO.puts "All clients started subscribing"
    else
      curClient = curClient + 1
      GenServer.cast(:"actor#{curClient}", {:startSubscribe, totalClients, curClient, self(), password})
      initialSubscribe(curClient, totalClients, password)
    end
  end

  def initialAction(curClient, totalClients, password, wordsNo) do
    if curClient == totalClients do
      # IO.inspect "All clients started tweeting"
    else
      curClient = curClient + 1
      # tweet = "Hello @u1 #hastag1"
      GenServer.cast(:"actor#{curClient}", {:startAction, totalClients, curClient, self(), password})
      initialAction(curClient, totalClients, password, wordsNo)
    end
  end

  def getRandomTweet(l, num) do
        words = "Today is a day that I’ve been looking very much forward to ALL YEAR LONG. It is one that you have heard me speak about many times before"
        words = String.split(words," ")
        hashTag =
        if(:rand.uniform(5) == 2) do
            h = round(0.25*num)
            [("#HASHTAG"<>Integer.to_string(:rand.uniform(h)))]
        else
            []
        end
        mentions =
        if(:rand.uniform(5) == 4) do
            h = round(0.20*num)
            [("@u"<>Integer.to_string(:rand.uniform(h)))]
        else
            []
        end
        words = words ++ hashTag ++ mentions
        wordSet = Enum.take_random(words, l)
        Enum.join(wordSet, " ")
    end

end
