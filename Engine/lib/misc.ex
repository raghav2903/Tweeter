defmodule Misc do

    def getRecentFeed(feed_list) do
        if length(feed_list) > 4 do
            Enum.take(feed_list, 5)
        else
            feed_list
        end
    end

    def getHashtags(tweet) do
        words_in_tweet = String.split(tweet, " ", trim: true)
        hashtags = Enum.reduce(words_in_tweet, [], fn(word, acc) ->
                                                                if String.starts_with?(word, "#") do
                                                                    [word | acc]
                                                                else
                                                                    acc
                                                                end
                                                   end)
        hashtags
    end

    def getMentions(tweet) do
        words_in_tweet = String.split(tweet, " ", trim: true)
        mentions = Enum.reduce(words_in_tweet, [], fn(word, acc) ->
                                                                if String.starts_with?(word, "@") do
                                                                    [Enum.at(String.split(word, "@"), 1) | acc]
                                                                else
                                                                    acc
                                                                end
                                                   end)
        mentions
    end    

    def getIP(tup) do
        {a, b, c, d} = tup
        "#{a}.#{b}.#{c}.#{d}"
    end


end