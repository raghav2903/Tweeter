defmodule QueryDB do
    
    def init({:ok}) do
        state = %{
                    hashTags: %{},  #hashtag to tweet_id list
                    mentioned: %{}, #user_id to tweet_id list
                    activePIDs: %{} #user_id to pid
                 }
        {:ok, state}
    end

    #return active pids list
    def handle_call({:get_active_pids_map}, _from, state) do
        active_pids_map = Map.get(state, :activePIDs)
        {:reply, active_pids_map, state}
    end
    
    #returns list of tweet_ids with hashtag
    def handle_call({:query_hashtag, hashtag}, _from, state) do
        reply = get_in(state, [:hashTags, hashtag])
        try do    
            if length(reply) > 0 do
                reply = {true, reply}
                {:reply, reply, state}
            end
        rescue
            ArgumentError -> reply = {false, reply}
                             {:reply, reply, state}
        end
    end

    #returns list of tweet_ids with mention
    def handle_call({:query_mention, mention}, _from, state) do
        reply = get_in(state, [:mentioned, mention])
        try do    
            if length(reply) > 0 do
                reply = {true, reply}
                {:reply, reply, state}
            end
        rescue
            ArgumentError -> reply = {false, reply}
                             {:reply, reply, state}
        end
    end

    #add user_id to active users list
    def handle_cast({:is_active, user_id, pid}, state) do
        active = Map.get(state, :activePIDs)
        active = Map.put(active, user_id, pid)
        state = Map.put(state, :activePIDs, active)
        {:noreply, state}
    end

    #remove user_id from active users list
    def handle_cast({:inactive, user_id}, state) do
        active = Map.get(state, :activePIDs)
        active = Map.delete(active, user_id)
        state = Map.put(state, :activePIDs, active)
        {:noreply, state}
    end

    #add tweet to hashtag list
    def handle_cast({:add_hashtag, hashtag, tweet_id}, state) do
        hashtag_map = Map.get(state, :hashTags)
        if Map.has_key?(hashtag_map, hashtag) do
            hashtag_list = Map.get(hashtag_map, hashtag)
            hashtag_list = [tweet_id | hashtag_list]
            hashtag_map = Map.put(hashtag_map, hashtag, hashtag_list)
            state = Map.put(state, :hashTags, hashtag_map)
            {:noreply, state}
        else
            hashtag_map = Map.put(hashtag_map, hashtag, [tweet_id])
            state = Map.put(state, :hashTags, hashtag_map)
            {:noreply, state}
        end 
    end

    #add tweet to hashtag list
    def handle_cast({:add_mention, mention, tweet_id}, state) do
        mentions_map = Map.get(state, :mentioned)
        if Map.has_key?(mentions_map, mention) do
            mentions_list = Map.get(mentions_map, mention)
            mentions_list = [tweet_id | mentions_list]
            mentions_map = Map.put(mentions_map, mention, mentions_list)
            state = Map.put(state, :mentioned, mentions_map)
            {:noreply, state}
        else
            mentions_map = Map.put(mentions_map, mention, [tweet_id])
            state = Map.put(state, :mentioned, mentions_map)
            {:noreply, state}
        end
    end

end