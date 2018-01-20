defmodule Tweeting do
  def getRandomTweet(l, totalClients) do
          words = "Today is a day that I’ve been looking very much forward to ALL YEAR LONG. It is one that you have heard me speak about many times before"
          words = String.split(words," ")
          hashTag =
          if(:rand.uniform(5) == 2) do
              h = round(0.25*totalClients)
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
          wordSet = Enum.take_random(words, l)
          wordSet = Enum.join(wordSet, " ")
   end
end
