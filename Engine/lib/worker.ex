defmodule Worker do
    use GenServer

    @timeout :infinity

    def init({:ok, worker_tag, num_of_userp_dbs}) do
        state = %{
                    tweet_count: 0,
                    worker_tag: worker_tag,     #worker name
                    num_of_userp_dbs: num_of_userp_dbs  #number of userp_dbs
                 }
        {:ok, state}
    end

    #register a new user
    def handle_call({:register_user, user_id, password, pid}, _from, state) do
        {bool, reply} = GenServer.call(:"db", {:register_user, user_id, password})
        if bool do
            #allocate a userp_db space for the new user
            num_of_userp_dbs = Map.get(state, :num_of_userp_dbs)
            which_userp_db = Enum.random(1..num_of_userp_dbs)
            GenServer.cast(:"userp_db#{which_userp_db}", {:new_user, user_id})
            #inform DB to add user_id and which userp_db its data is stored in
            GenServer.cast(:"db", {:add_userID_to_userpDB_map, user_id, which_userp_db})
            #add to active pids list
            GenServer.cast(:"querydb", {:is_active, user_id, pid})
            {:reply, {bool, reply}, state}
        else
            {:reply, {bool, reply}, state}
        end
    end

    #validate login of a new user
    def handle_call({:login, user_id, password, pid}, _from, state) do
        {bool, reply} = GenServer.call(:"db", {:login, user_id, password}, @timeout)
        if bool do
            #add to active pids list
            GenServer.cast(:"querydb", {:is_active, user_id, pid})
            #display 5 most recent tweets in feed
            recent_tweetID_list = getRecentFeed(user_id)
            if length(recent_tweetID_list) > 0 do
                Enum.map(recent_tweetID_list, fn tweet_id ->
                                                    tweet = GenServer.call(:"db", {:get_tweet, tweet_id}, @timeout)
                                                    GenServer.cast(pid, {:display, "#{tweet_id} #{tweet}"})
                                              end)
            end
            {:reply, {bool, reply}, state}
        else
            {:reply, {bool, reply}, state}
        end
    end

    #return the 5 most recent list in user_ids' feed
    def handle_call({:get_feed, user_id}, _from, state) do
        recent_tweetID_list = getRecentFeed(user_id)
        if length(recent_tweetID_list) > 0 do
            reply = Enum.reduce(recent_tweetID_list, [], fn tweet_id, acc ->
                                                                            tweet = GenServer.call(:"db", {:get_tweet, tweet_id}, @timeout)
                                                                            ["#{tweet_id} #{tweet}" | acc]
                                                         end)
            {:reply, reply, state}
        else
            {:reply, ["no tweets in your feed"], state}
        end
    end

    #return tweets containing the hashtag
    def handle_call({:query_hashtag, hashtag}, _from, state) do
        {bool, tweet_id_list} = GenServer.call(:"querydb", {:query_hashtag, hashtag}, @timeout)
        if bool do
            reply = handleQuery(tweet_id_list)
            {:reply, reply, state}
        else
            {:reply, ["no tweet found containing hashtag : #{hashtag}"], state}
        end
    end

    #return tweets containing the hashtag
    def handle_call({:query_mention, mention}, _from, state) do
        {bool, tweet_id_list} = GenServer.call(:"querydb", {:query_mention, mention}, @timeout)
        if bool do
            reply = handleQuery(tweet_id_list)
            {:reply, reply, state}
        else
            {:reply, ["no tweet found containing mention : #{mention}"], state}
        end
    end

    #handle a new tweet
    def handle_cast({:tweet, user_id, tweet}, state) do
        #update tweet count
        tweet_count = Map.get(state, :tweet_count)
        tweet_count = tweet_count + 1
        state = Map.put(state, :tweet_count, tweet_count)
        #generate a tweet_id for the tweet to store in db
        worker_tag = Map.get(state, :worker_tag)
        tweet_id = Enum.join([worker_tag, tweet_count], "")
        #add tweet to db
        GenServer.cast(:"db", {:add_tweet, tweet_id, tweet})

        which_userp_db = GenServer.call(:"db", {:get_which_userp_db_userID_in, user_id}, @timeout)
        subscribers_list = GenServer.call(:"userp_db#{which_userp_db}", {:get_subscriber_list, user_id}, @timeout)
        #add the tweet to user_ids tweet list
        add_tweet_to_userids_tweetList(user_id, tweet_id, which_userp_db)
        #add tweet to subscribers feed
        add_tweet_to_subscribers_feed(tweet_id, subscribers_list)
        #display the tweet to all active subscribers
        display_tweet_to_active_subscribers(subscribers_list, "#{tweet_id} #{tweet}")

        #parse for hashtags and add to hashtags list
        hashtags = Misc.getHashtags(tweet)
        if length(hashtags) > 0 do
            Enum.map(hashtags, fn hashtag -> GenServer.cast(:"querydb", {:add_hashtag, hashtag, tweet_id}) end)
        end

        #parse for mentions and add to mentioned list
        mentions = Misc.getMentions(tweet)
        if length(mentions) > 0 do
            Enum.map(mentions, fn mention -> if GenServer.call(:"db", {:validate_user, mention}, @timeout) do
                                                GenServer.cast(:"querydb", {:add_mention, mention, tweet_id})
                                             end
                               end)
        end
        {:noreply, state}
    end

    #handle a retweet
    def handle_cast({:retweet, user_id, tweet_id}, state) do
        which_userp_db = GenServer.call(:"db", {:get_which_userp_db_userID_in, user_id}, @timeout)
        subscribers_list = GenServer.call(:"userp_db#{which_userp_db}", {:get_subscriber_list, user_id}, @timeout)
        #add the tweet to user_ids tweet list
        add_tweet_to_userids_tweetList(user_id, tweet_id, which_userp_db)
        #add tweet to subscribers feed
        add_tweet_to_subscribers_feed(tweet_id, subscribers_list)
        #display the tweet to all active subscribers
        tweet = GenServer.call(:"db", {:get_tweet, tweet_id}, @timeout)
        display_tweet_to_active_subscribers(subscribers_list, tweet_id <> " " <> tweet)
        {:noreply, state}
    end

    #handle log off
    def handle_cast({:remove_user_pid_from_active_pids_list, user_id}, state) do
        #remove from active pids list
        GenServer.cast(:"querydb", {:inactive, user_id})
        {:noreply, state}
    end

    #subscribe user_id to subscribe_id
    def handle_cast({:subscribe, user_id, subscribe_id}, state) do
        if GenServer.call(:"db", {:validate_user, subscribe_id}) do
            which_userp_db = GenServer.call(:"db", {:get_which_userp_db_userID_in, subscribe_id}, @timeout)
            GenServer.cast(:"userp_db#{which_userp_db}", {:subscribe, user_id, subscribe_id})
            {:noreply, state}
        else
            {:noreply, state}
        end
    end

    defp add_tweet_to_userids_tweetList(user_id, tweet_id, which_userp_db) do
        GenServer.cast(:"userp_db#{which_userp_db}", {:add_tweet_to_userID_tweetList, user_id, tweet_id})
    end

    defp add_tweet_to_subscribers_feed(tweet_id, subscribers_list) do
        Enum.map(subscribers_list, fn subscriber_id ->
                                                       which_userp_db = GenServer.call(:"db", {:get_which_userp_db_userID_in, subscriber_id}, @timeout)
                                                       GenServer.cast(:"userp_db#{which_userp_db}", {:add_tweet_to_userID_feedList, subscriber_id, tweet_id})
                                    end)
    end

    defp display_tweet_to_active_subscribers(subscribers_list, tweet) do
        active_pids_map = GenServer.call(:"querydb", {:get_active_pids_map}, @timeout)
        active_pids_list = Enum.reduce(subscribers_list, [], fn(subscriber_id, acc) ->
                                                                                if Map.has_key?(active_pids_map, subscriber_id) do
                                                                                    [Map.get(active_pids_map, subscriber_id) | acc]
                                                                                else
                                                                                    acc
                                                                                end
                                                             end)
        Enum.map(active_pids_list, fn pid ->
                                            GenServer.cast(pid,{:display, tweet})
                                   end)
    end

    defp handleQuery(tweet_id_list) do
        Enum.reduce(tweet_id_list, [], fn tweet_id, acc ->
                                                            tweet = GenServer.call(:"db", {:get_tweet, tweet_id}, @timeout)
                                                            ["#{tweet_id} #{tweet}" | acc]
                                                end)
    end

    defp getRecentFeed(user_id) do
        which_userp_db = GenServer.call(:"db", {:get_which_userp_db_userID_in, user_id}, @timeout)
        feed_list = GenServer.call(:"userp_db#{which_userp_db}", {:get_feed_list, user_id}, @timeout)
        recent_tweetID_list = Misc.getRecentFeed(feed_list)
        recent_tweetID_list
    end

end
