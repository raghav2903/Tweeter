defmodule Master do
    use GenServer

    @timeout :infinity
    @num_of_workers 3
    @num_of_userp_dbs 2
    @cookie :common_cookie
    @serverName :serverName

    def getCookie do
        @cookie
    end

    def getServerName do
      @serverName
    end

    def init({:ok}) do
        IO.inspect "Master Server started"
        {:ok, _db_pid} = GenServer.start_link(DB, {:ok}, name: :"db")
        {:ok, _db_pid} = GenServer.start_link(QueryDB, {:ok}, name: :"querydb")
        Enum.map(1..@num_of_workers, fn worker_num ->
                                        {:ok, _worker_pid} = GenServer.start_link(Worker, {:ok, "w#{worker_num}", @num_of_userp_dbs}, name: :"worker#{worker_num}")
                                        end)
        Enum.map(1..@num_of_userp_dbs, fn userp_db_num ->
                                        {:ok, _userp_db_pid} = GenServer.start_link(User_Profiles, {:ok}, name: :"userp_db#{userp_db_num}")
                                        end)
        state = %{
                    user_session_map: %{},   #session id to user_id
                    session_count: 0,    #session counter
                    tweets_handled: 0 #for performance evaluation
                 }
        # GenServer.cast(self(), {:print_performance})
        {:ok, state}
    end

    def startLoadBalancer() do
        # {:ok, [{_, _, _}, {ip, _, _}]} = :inet.getif
		    {:ok, [{ip, _, _}, {_, _, _}]} = :inet.getif 
        ip = "server@#{Misc.getIP(ip)}"

        #Create a server node
        {:ok, _} = Node.start(String.to_atom(ip))
        Node.set_cookie(getCookie())
        IO.inspect ip
        :global.sync
    end

    #register a new user
    def handle_call({:register_user, user_id, password}, from, state) do
        pid = elem(from, 0)
        worker_num = Enum.random(1..@num_of_workers)
        {bool, reply} = GenServer.call(:"worker#{worker_num}", {:register_user, user_id, password, pid}, @timeout)
        if bool do
            session_count = Map.get(state, :session_count)
            user_session_map = Map.get(state, :user_session_map)
            user_session_map = Map.put(user_session_map, "s#{session_count}", user_id)
            reply = {true, "s#{session_count}"}
            session_count = session_count + 1
            state = Map.put(state, :session_count, session_count)
            state = Map.put(state, :user_session_map, user_session_map)
            {:reply, reply, state}
        else
            {:reply, {bool, reply}, state}
        end
    end

    #validate login of an user and give a session id
    def handle_call({:login, user_id, password}, from, state) do
        pid = elem(from, 0)
        worker_num = Enum.random(1..@num_of_workers)
        {bool, reply} = GenServer.call(:"worker#{worker_num}", {:login, user_id, password, pid}, @timeout)
        if bool do
            session_count = Map.get(state, :session_count)
            user_session_map = Map.get(state, :user_session_map)
            user_session_map = Map.put(user_session_map, "s#{session_count}", user_id)
            reply = {true, "s#{session_count}"}
            session_count = session_count + 1
            state = Map.put(state, :session_count, session_count)
            state = Map.put(state, :user_session_map, user_session_map)
            {:reply, reply, state}
        else
            {:reply, {bool, reply}, state}
        end
    end

    #return tweets containing the particular hashtag
    def handle_call({:query_hashtag, user_id, session_id, hashtag}, _from, state) do
        if validate_user(state, user_id, session_id) do
            worker_num = Enum.random(1..@num_of_workers)
            reply = GenServer.call(:"worker#{worker_num}", {:query_hashtag, hashtag}, @timeout)
            {:reply, reply, state}
        else
            {:reply, ["invalid session"], state}
        end
    end

    #return tweets containing the particular mention
    def handle_call({:query_mention, user_id, session_id, mention}, _from, state) do
        if validate_user(state, user_id, session_id) do
            worker_num = Enum.random(1..@num_of_workers)
            reply = GenServer.call(:"worker#{worker_num}", {:query_mention, mention}, @timeout)
            {:reply, reply, state}
        else
            {:reply, ["invalid session"], state}
        end
    end

    #return user_ids' latest tweets
    def handle_call({:get_feed, user_id, session_id}, _from, state) do
        if validate_user(state, user_id, session_id) do
            worker_num = Enum.random(1..@num_of_workers)
            reply = GenServer.call(:"worker#{worker_num}", {:get_feed, user_id}, @timeout)
            {:reply, reply, state}
        else
            {:reply, ["invalid session"], state}
        end
    end

    #handle log-off of an user
    def handle_cast({:logoff, user_id, session_id}, state) do
        user_session_map = Map.get(state, :user_session_map)
        if Map.has_key?(user_session_map, session_id) do
            #remove the session for the user_id
            user_session_map = Map.delete(user_session_map, session_id)
            state = Map.put(state, :user_session_map, user_session_map)
            #remove the user_id from the active user list
            worker_num = Enum.random(1..@num_of_workers)
            GenServer.cast(:"worker#{worker_num}", {:remove_user_pid_from_active_pids_list, user_id})
            {:noreply, state}
        else
            {:noreply, state}
        end
    end

    #handle a new incoming tweet
    def handle_cast({:tweet, user_id, session_id, tweet}, state) do
        if validate_user(state, user_id, session_id) do
            tweets_handled = Map.get(state, :tweets_handled)
            tweets_handled = tweets_handled + 1
            state = Map.put(state, :tweets_handled, tweets_handled)
            worker_num = Enum.random(1..@num_of_workers)
            GenServer.cast(:"worker#{worker_num}", {:tweet, user_id, tweet})
            {:noreply, state}
        else
            #ignore invalid session
            {:noreply, state}
        end
    end

    #handle a retweet
    def handle_cast({:retweet, user_id, session_id, tweet_id}, state) do
        if validate_user(state, user_id, session_id) do
            tweets_handled = Map.get(state, :tweets_handled)
            tweets_handled = tweets_handled + 1
            state = Map.put(state, :tweets_handled, tweets_handled)
            worker_num = Enum.random(1..@num_of_workers)
            GenServer.cast(:"worker#{worker_num}", {:retweet, user_id, tweet_id})
            {:noreply, state}
        else
            #ignore invalid session
            {:noreply, state}
        end
    end

    #handle subscribing to an user
    def handle_cast({:subscribe, user_id, session_id, subscribe_id}, state) do
        if validate_user(state, user_id, session_id) do
            worker_num = Enum.random(1..@num_of_workers)
            GenServer.cast(:"worker#{worker_num}", {:subscribe, user_id, subscribe_id})
            {:noreply, state}
        else
            {:noreply, state}
        end
    end

    # def handle_cast({:print_performance}, state) do
    #     time = @performance_rate/1000
    #     tweet_count = Map.get(state, :tweets_handled)
    #     tweet_count = 0
    #     state = Map.put(state, :tweets_handled, tweet_count)
    #     Process.send_after(self(), {:hold_until}, @performance_rate)
    #     {:noreply, state}
    # end
    #
    # def handle_cast({:print}, state) do
    #     GenServer.cast(:"userp_db1", {:print})
    #     {:noreply, state}
    # end
    #
    # def handle_info({:hold_until}, state) do
    #     GenServer.cast(self(), {:print_performance})
    #     {:noreply, state}
    # end

    defp validate_user(state, user_id, session_id) do
        user_session_map = Map.get(state, :user_session_map)
        if Map.has_key?(user_session_map, session_id) do
            valid_user_id = Map.get(user_session_map, session_id)
            if String.equivalent?(user_id, valid_user_id) do
                true
            else
                false
            end
        else
            false
        end
    end



end
