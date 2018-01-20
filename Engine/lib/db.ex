defmodule DB do
    use GenServer

    def init({:ok}) do
        state = %{
                    tweets: %{},    #tweet_id to tweet text
                    userID_to_userpDB_num_map: %{}, #user_id to userp_db number
                    all_users_map: %{}   #user_id to password
                 }
        {:ok, state}
    end

    #register a new user
    def handle_call({:register_user, user_id, password}, _from, state) do
        all_users_map = Map.get(state, :all_users_map)
        if Map.has_key?(all_users_map, user_id) do
            #user already exists
            {:reply, {false, "user_id already exists"}, state}
        else
            #register the new user
            all_users_map = Map.put(all_users_map, user_id, password)
            state = Map.put(state, :all_users_map, all_users_map)
            {:reply, {true, "registration successful"}, state}
        end
        
    end

    #returns the tweet with specified tweet_id
    def handle_call({:get_tweet, tweet_id}, _from, state) do
        reply = get_in(state, [:tweets, tweet_id])
        {:reply, reply, state}
    end

    #validate the login of a user
    def handle_call({:login, user_id, password}, _from, state) do
        all_users_map = Map.get(state, :all_users_map)
        
        if Map.has_key?(all_users_map, user_id) do
            #user id exists, now check for password
            original_password = Map.get(all_users_map, user_id)
            if String.equivalent?(password, original_password) do
                {:reply, {true, "login successful"}, state}
            else
                {:reply, {false, "user_id and password don't match"}, state}
            end
        else
            #user_id doesn't exist
            {:reply, {false, "user_id doesn't exist"}, state}
        end
    
    end

    #return which userp_db contains the user_ids data
    def handle_call({:get_which_userp_db_userID_in, user_id}, _from, state) do
        which_userp_db = get_in(state, [:userID_to_userpDB_num_map, user_id])
        {:reply, which_userp_db, state}
    end

    #verify is user_id exists
    def handle_call({:validate_user, user_id}, _from, state) do
        users_map = Map.get(state, :all_users_map)
        if Map.has_key?(users_map, user_id) do
            {:reply, true, state}
        else
            {:reply, false, state}
        end
    end

    #add new tweet to total tweet list
    def handle_cast({:add_tweet, tweet_id, tweet}, state) do
        tweets = Map.get(state, :tweets)
        tweets = Map.put(tweets, tweet_id, tweet)
        state = Map.put(state, :tweets, tweets)
        {:noreply, state}
    end

    #add user_id to userp_db map
    def handle_cast({:add_userID_to_userpDB_map, user_id, which_userp_db}, state) do
        userID_to_userpDB_num_map = Map.get(state, :userID_to_userpDB_num_map)
        userID_to_userpDB_num_map = Map.put(userID_to_userpDB_num_map, user_id, which_userp_db)
        state = Map.put(state, :userID_to_userpDB_num_map, userID_to_userpDB_num_map)
        {:noreply, state}
    end

end