Date: October 23rd, 2017

Group Members:

1. Suhas Kumar Bharadwaj, UFID: 16120229
2. Raghav Ravishankar, UFID: 19995874

Usage:
	
	 "escript numNodes numRequests"

Working:

	1. The network is getting initialized and new nodes are able to join the network seamlessly. 
	2. They are able to share their routing tables with each other and provide for better routing capabilities.
	3. The number of hops taken to reach the destination are well within the bounds of O(log n) 
	4. For very few nodes, it is slighlty above the bound due to the fact that the routing tables haven't got populated completely. 
	
Largest Networks Used:
	1. numNodes - 1000
	   numRequests - 10
	   Average Number of Hops - 2.241
	   
	2. numNodes - 500
	   numRequests - 15
	   Average Number of Hops - 
		
Sample Outputs:
	
	escript 1000 10
	
	Column1: Number of nodes
	Column2: The number of requests that each node should send

