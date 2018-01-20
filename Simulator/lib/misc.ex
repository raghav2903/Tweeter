defmodule Misc do

    def getIP(tup) do
        {a, b, c, d} = tup
        "#{a}.#{b}.#{c}.#{d}"
    end

end
