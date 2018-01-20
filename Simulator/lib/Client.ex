defmodule Client do
  use GenServer
  @cookie :common_cookie
  @serverName :masterName
  @timeout :infinity

    def getServerName do
      @serverName
    end

    def getCookie do
        @cookie
    end

    defp getPID do
        :global.whereis_name(Client.getServerName())
    end

    def init({:ok, clientNo, totalClients, masterClientPID}) do
        serverPID = getPID()
        user_id = "u#{Integer.to_string(clientNo)}"
        # IO.inspect user_id, label: "Started"
        password = "password"
        {bool, session_id} = GenServer.call(serverPID, {:register_user, user_id, password})  #User Id is Client Nos
        GenServer.cast(masterClientPID, {:ackRegister, bool, self(), totalClients, password})
        {:ok, [user_id, clientNo, serverPID, totalClients, masterClientPID, session_id]}
    end

    def calcFolSub(clientNo, serverPID, clientPID, totalClients, masterClientPID, password, session_id, user_id) do
      followers = Float.round(totalClients * (1/clientNo))
      followers =
      cond do
        followers == totalClients ->
          followers - 1
        true ->
          followers
      end
      makeFolList(clientNo, totalClients, followers, [], 0, serverPID, masterClientPID, password, session_id, user_id)
    end

    def makeFolList(clientNo, totalClients, followers, folList, subscribeClientNo, serverPID, masterClientPID, password, session_id, user_id) do
      if length(folList) == followers do
        # IO.puts "Client No: #{clientNo}"
        # IO.puts "No. of Followers: #{followers}"
        # IO.inspect folList
        # IO.inspect self(), label: "Done Subscribing"
        # IO.inspect "*******************************"
        GenServer.cast(masterClientPID, {:ackSubscribe, self(), totalClients, password, serverPID})
      else
        subscribeClientNo = subscribeClientNo + 1
        folList =
        cond do
          subscribeClientNo != clientNo ->
            subscribe_id = "u#{Integer.to_string(subscribeClientNo)}"
            GenServer.cast(serverPID, {:subscribe, user_id, session_id, subscribe_id})
            List.insert_at(folList, -1, subscribeClientNo)
          true ->
            folList
        end
        makeFolList(clientNo, totalClients, followers, folList, subscribeClientNo, serverPID, masterClientPID, password, session_id, user_id)
      end
    end

    def handle_cast({:startSubscribe, totalClients, curClient, masterClientPID, password}, state) do
      serverPID = getPID()
      user_id = List.first(state)
      session_id = List.last(state)
      calcFolSub(curClient, serverPID, self(), totalClients, masterClientPID, password, session_id, user_id)
      {:noreply, state}
    end

    def handle_cast({:display, tweet}, state) do
      user_id = List.first(state)
      # IO.inspect "#{user_id} received the tweet: #{tweet}"
      tweet_id = Enum.at(String.split(tweet, " "), 0)
      serverPID = getPID()
      user_id = List.first(state)
      session_id = List.last(state)
      GenServer.cast(serverPID, {:retweet, user_id, session_id, tweet_id})
      {:noreply, state}
    end

    def handle_cast({:startLogin, totalClients, curClient, masterClientPID, password}, state) do
      serverPID = getPID()
      user_id = "u#{Integer.to_string(curClient)}"
      {bool, reply} = GenServer.call(serverPID, {:login, user_id, password}, @timeout)
      session_id = reply
      state = List.replace_at(state,-1,session_id)
      {:noreply, state}
    end

    def handle_cast({:startAction, totalClients, curClient, masterClientPID, password}, state) do
      serverPID = getPID()
      user_id = List.first(state)
      session_id = List.last(state)
      #
      wordsNo = Enum.random(3..8)
      words = "Today is a day that I’ve been looking very much forward to ALL YEAR LONG. It is one that you have heard me speak about many times before"
      words = String.split(words," ")
      hashTag =
      if(:rand.uniform(5) == 2) do
          h = round(0.3*totalClients)
          [("#HASHTAG"<>Integer.to_string(:rand.uniform(h)))]
      else
          []
      end
      mentions =
      if(:rand.uniform(5) == 4) do
          [("@u"<>Integer.to_string(:rand.uniform(totalClients)))]
      else
          []
      end
      words = words ++ hashTag ++ mentions
      tweet = Enum.take_random(words, wordsNo)
      tweet = Enum.join(tweet, " ")
      # tweet = "Hello @u1 #hastag1"
      GenServer.cast(serverPID, {:tweet, user_id, session_id, tweet})
      #
      randFun = Enum.random(1..4)
      #  Enum.random(2..4)
      randFun = Integer.to_string(randFun)

        case randFun do
          "1" ->
                # IO.inspect "Log Off and Log In"
                GenServer.cast(serverPID, {:logoff, user_id, session_id})
                # Process.sleep(1000)
                {bool, reply} = GenServer.call(serverPID, {:login, user_id, password}, @timeout)
                session_id = reply
                state = List.replace_at(state, -1, session_id)
                # Process.sleep(1000)
                Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password}, 1000)
                  {:noreply, state}

          # "2" ->
          #         # IO.inspect "Tweet"
          #         Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password, tweet}, 1000)
          #         {:noreply, state}

          "2" ->
                  # IO.inspect "Get Feed"
                  list = GenServer.call(serverPID, {:get_feed, user_id, session_id}, @timeout)
                  # Process.sleep(1000)
                  IO.inspect list, label: "#{user_id} feed:"
                  Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password}, 1000)
                  {:noreply, state}

          "3" ->
                  # IO.inspect "queryhashtag"
                  h = round(0.3*totalClients)
                  hashTag = ("#HASHTAG"<>Integer.to_string(:rand.uniform(h)))
                  list = GenServer.call(serverPID, {:query_hashtag, user_id, session_id, hashTag}, @timeout)
                  # Process.sleep(1000)
                  IO.inspect list, label: "#{user_id} hashtag"
                  Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password}, 1000)
                  {:noreply, state}

          "4" ->
                  # IO.inspect "queryMention"
                  h = round(0.20*totalClients)
                  userMention = ("u"<>Integer.to_string(:rand.uniform(h)))
                  list = GenServer.call(serverPID, {:query_mention, user_id, session_id, userMention}, @timeout)
                  IO.inspect list, label: "#{user_id} mention:"
                  Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password}, 1000)
                  {:noreply, state}
          # 6 ->

          _ ->  IO.inspect "Operation invalid"
                Process.send_after(self(), {:timeout, totalClients, curClient, masterClientPID, password}, 1000)
        end

    end


    def handle_info({:timeout, totalClients, curClient, masterClientPID, password}, state) do
      :timer.sleep(1000*curClient)
      GenServer.cast(self(), {:startAction, totalClients, curClient, masterClientPID, password})
      {:noreply, state}
    end

end
