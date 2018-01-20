defmodule Project4 do
    use GenServer
    @masterName :masterName

    def main(_args) do
        #{_,argList,_} = OptionParser.parse(args)
        Master.startLoadBalancer()
        {:ok, master_pid} = GenServer.start_link(Master, {:ok}, [])
        :global.register_name(@masterName, master_pid)
        :global.sync
       # :global.register_name(@masterName, master_pid)

        # {_bool, reply1} = GenServer.call(master_pid, {:register_user, "user1", "user123"})
        # {_bool, reply2} = GenServer.call(master_pid, {:register_user, "user2", "user123"})
        # GenServer.cast(master_pid, {:print})
        # GenServer.cast(master_pid, {:subscribe, "user2", reply2, "user1"})
        # GenServer.cast(master_pid, {:logoff, "user2", reply2})

        # GenServer.cast(master_pid, {:tweet, "user1", reply1, "hello @user1"})
        # GenServer.cast(master_pid, {:tweet, "user1", reply1, "bye @user1"})
        # GenServer.cast(master_pid, {:print})
        # GenServer.cast(master_pid, {:print})
        # IO.inspect GenServer.call(master_pid, {:get_feed, "user2", reply2})
        # {_bool, _reply1} = GenServer.call(master_pid, {:login, "user2", "user123"})
        # IO.inspect GenServer.call(master_pid, {:query_mention, "user1", reply1, "@user1"})

        # GenServer.cast(master_pid, {:subscribe, "user1", reply1, "user2"})

        # GenServer.cast(master_pid, {:subscribe, "user2", reply2, "user1"})
        # GenServer.cast(master_pid, {:logoff, "user1", reply1})
        # GenServer.cast(master_pid, {:logoff, "user2", reply2})
        # Process.sleep(20)
        # GenServer.cast(master_pid, {:logoff, "user1", reply1})
        #GenServer.cast(master_pid, {:tweet, "user2", reply2, "hello"})
        # GenServer.cast(master_pid, {:print})

        # {_bool, reply1} = GenServer.call(master_pid, {:login, "user1", "user123"})
        # GenServer.cast(master_pid, {:tweet, "user2", reply2, "bye"})
        # {_bool, reply} = GenServer.call(master_pid, {:login, "user1", "user123"})
        # IO.inspect reply
        # GenServer.cast(master_pid, {:logoff, "user1", reply})
        # IO.inspect reply
        # receive do
        #     {:display, tweet} ->
        #                         IO.puts tweet
        #                         tweet_id = Enum.at(String.split(tweet, " "), 0)
        #                         GenServer.cast(master_pid, {:retweet, "user1", reply1, tweet_id})
        #                         Process.sleep(1000)
        #                         GenServer.cast(master_pid, {:print})
        # end
        # receive do
        #     {:display, tweet} ->
        #                         IO.puts tweet
        # end
        temp()

    end

    def temp do
        receive do
            # {:display, tweet} -> IO.puts tweet
            #                      temp()
        end
    end


end
