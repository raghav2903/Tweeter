defmodule User_Profiles do
    use GenServer

    def init({:ok}) do
        state = %{
                    userData: %{},  #user_id to %{[tweets], [feed], [subscribers]}
                 }
        {:ok, state}
    end

    #return the user_ids' subscriber list
    def handle_call({:get_subscriber_list, user_id}, _from, state) do
        subscribers_list = get_in(state, [:userData, user_id, :subscribers])
        {:reply, subscribers_list, state}
    end

    #return user_ids' feed list
    def handle_call({:get_feed_list, user_id}, _from, state) do
        feed_list = get_in(state, [:userData, user_id, :feed])
        {:reply, feed_list, state}
    end

    #allots data space for the new user
    def handle_cast({:new_user, user_id}, state) do
        user_data_map = Map.get(state, :userData)
        user_data = %{tweets: [], feed: [], subscribers: []}  #tweets, feed, subscribers
        user_data_map = Map.put(user_data_map, user_id, user_data) 
        state = Map.put(state, :userData, user_data_map)
        {:noreply, state}
    end

    #adds the tweet to user_ids tweets list
    def handle_cast({:add_tweet_to_userID_tweetList, user_id, tweet_id}, state) do
        tweet_list = get_in(state, [:userData, user_id, :tweets])
        tweet_list = [tweet_id | tweet_list]
        state = put_in(state, [:userData, user_id, :tweets], tweet_list)
        {:noreply, state}
    end

    #adds the tweet to user_ids feed list
    def handle_cast({:add_tweet_to_userID_feedList, user_id, tweet_id}, state) do
        feed_list = get_in(state, [:userData, user_id, :feed])
        feed_list = [tweet_id | feed_list]
        state = put_in(state, [:userData, user_id, :feed], feed_list)
        {:noreply, state}
    end

    #subcribe user_id to subscribe_id
    def handle_cast({:subscribe, user_id, subscribe_id}, state) do
        subscribers_list = get_in(state, [:userData, subscribe_id, :subscribers])
        subscribers_list = [user_id | subscribers_list]
        state = put_in(state, [:userData, subscribe_id, :subscribers], subscribers_list)
        {:noreply, state}
    end
    
    #manual testing purpose
    def handle_cast({:print}, state) do
        IO.inspect state
        {:noreply, state}
    end

end