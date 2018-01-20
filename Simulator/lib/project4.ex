defmodule Project4 do

    def main(args) do
        {_,argList,_} = OptionParser.parse(args)
        if length(argList) == 0 do
            IO.puts "Invalid Argument"
        else
          [serverIP | [noClients | _]] = argList
          numClients = String.to_integer(noClients)
          Project4.initializeClient(serverIP, numClients, numClients)
        end

        receive do

        end
    end

    def initializeClient(serverIP, numClients, totalClients) do
      IO.inspect "Starting Client"
      Project4.startClient(serverIP, numClients, totalClients)
      {:ok, masterClientPID} = GenServer.start_link(MasterClient, {:ok, serverIP, numClients, totalClients}, name: :"masterClient")
    end

    def startClient(serverIP, clientNo, totalClients) do
        # {:ok, [{_, _, _}, {clientIP, _, _}]} = :inet.getif
        {:ok, [{clientIP, _, _}, {_, _, _}]} = :inet.getif             
        IO.inspect "*******************************"
        clientIP = "client@#{Misc.getIP(clientIP)}"
        serverIP = "server@#{serverIP}"
        #Create a client node and connect to server
        {:ok,_} = Node.start(String.to_atom(clientIP))
        Node.set_cookie(Client.getCookie)
        Node.connect(String.to_atom(serverIP))
        IO.inspect clientIP, label: "Connected to Server"
        IO.inspect "*******************************"

        :global.sync
    end
end
