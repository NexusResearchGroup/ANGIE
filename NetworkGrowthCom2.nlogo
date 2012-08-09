;;
;; Model: agent-based modeling the network growth and the Minneapolis skyway network
;; The forumlation of the models can be found in the papers
;; "A positive theory of network connectiviy" and
;; "The structure and dynamics of a skyway network"
;;  Date: April 12, 2012 
;;  Questions about the code can be sent to Arthur Huang at huang284@umn.edu 
;;

extensions [gis]
globals 
  [  
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
   ;; global variables   ;;;;;;;;;;
   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  nodes-dataset skyways-dataset block-dataset
    completelinks-dataset
    infinity  ;; a very large number
   sequence 
   ;cost
   roadness;; list of nodes that have the minimum x or y
              ;; this is used to calculate roadness
   totalEfficiency  ;; total network efficiency
   avgCoeff  ;; average clustering coefficient 
   node-start  ;; a node to start a link
   node-end    ;; a node at the end of a link 
   ;unitedgecost
   outputlinks
   matchratio
   totmatchratio 
   ;delta
   matchratio-list 
   actualmatchlinks 
   connect
   degree-centrality
   closeness-centrality 
   straightness-centrality
   
  ]
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;  
;;agents in the skyway model
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [buildings building]
undirected-link-breed [skyways skyway]
undirected-link-breed [simulinks simulink]
undirected-link-breed [completelinks completelink]
undirected-link-breed [ roads road]

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;agents in gried-like city models
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
breed [locations location]

;; variables in the skyway agents
skyways-own
[
    origin
    destination
    len
    year
 ]

; varialbes in the building agents


buildings-own
[
  rand
  distance-from-other-buildings ;; weight of each edge (0 stands for connecting to itself, infinity stands for no connection)
  profit-list ;; list of profits to each node
  node-candidate-list ;; list of nodes to be connected for each round 
                      ;; the sequence of the members in the list is the same as the profit-list
  accessiblity  ;; profit from the whole network
  num-of-neibor 
  closeness  
  betweeness
  ;cost
  straightness
  nodelist ;; list of nodes to be added (corresponding to the profit list)
  sum_of_straightness
  information  
  marginalProfitlist
  firstconnectyear
  space-list 
  ;profitInLastRound
  prev   ;; list of previous nodes in a shortest path
  ;; all the nodes on the shortest path
  shortest-path-nodes 
  connectedList ;; a list of that can be connected (it documents the nearest four nodesw)
  employee  ;; employees in a building
  ;searched  ;; index to see if a building has been searched before in comparing generated network with actual network
   space1962  space1963  space1964  space1965  space1966  space1967  space1968  space1969  space1970  space1971  space1972  space1973  space1974  space1975  space1976  space1977  space1978 
   space1979  space1980  space1981  space1982  space1983  space1984  space1985  space1986  space1987  space1988  
   space1989  space1990  space1991  space1992  space1993  space1994  space1995  space1996  space1997  space1998  
   space1999  space2000  space2001  space2002  
   space
   blockID
] 

; variables in the location agents
locations-own
[
  rand
  distance-from-other-locations ;; weight of each edge (0 stands for connecting to itself, infinity stands for no connection)
  profit-list ;; list of profits to each node
  node-candidate-list ;; list of nodes to be connected for each round 
                      ;; the sequence of the members in the list is the same as the profit-list
  accessiblity  ;; profit from the whole network
  num-of-neibor 
  closeness  
  betweeness
  ;cost
  straightness
  nodelist ;; list of nodes to be added (corresponding to the profit list)
  sum_of_straightness
  information  
  marginalProfitlist
  firstconnectyear
  space-list 
  ;profitInLastRound
  prev   ;; list of previous nodes in a shortest path
  ;; all the nodes on the shortest path
  shortest-path-nodes 
  connectedList ;; a list of that can be connected (it documents the nearest four nodesw)
  employee  ;; employees in a building
  ;searched  ;; index to see if a building has been searched before in comparing generated network with actual network
]


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;set up the landscape given different choices  ;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup
  
  
  set infinity 9999999999  ;; set infinity to be a very large number
  ;set totalEfficiency  0
  ask patches [set pcolor white]

  ifelse Scenario = "Minneapolis skway"
  [ setup-skyway-scenario ]
  [ setup-gridcity-scenario]

end

to setup-gridcity-scenario
  clear-all
  clear-patches
  clear-drawing
  clear-all-plots
  clear-output
  set-default-shape locations "circle"
  ask patches [set pcolor white]
  ;; sprout breed number [commands]: create a lcoation 
  ask patches with [abs pxcor < (grid-size / 2) and abs pycor < (grid-size / 2)] [ sprout-locations 1 [ set color green ] ]
  ask locations [setxy ( xcor * scale) ( ycor * scale)  set accessiblity 0  set marginalProfitlist [] set distance-from-other-locations [] set shortest-path-nodes  []  set nodelist [] set connectedList []]
  
  
  ifelse Scenario = "Single-center grid-like city"
  [ ask locations [    if xcor = 0 and ycor = 0   [ set color red  set size 1]]]
  [ ifelse Scenario = "Two-center grid-like city" [ask locations [ if ( xcor = -1 * int(grid-size / 4) * scale  and ycor = 0) or ( xcor = int(grid-size / 4) * scale and ycor = 0)  [ set color red  set size 1] ]]
    [ ifelse Scenario = "Four-center grid-like city" [ask locations [  if (xcor = -1 * int(grid-size / 4) * scale and ycor = 0) or ( xcor =  int(grid-size / 4) * scale and ycor = 0) or (xcor = 0 and ycor = -1 * int(grid-size / 4) * scale) or (xcor  = 0 and ycor = int(grid-size / 4) * scale)  [ set color red  set size 1] ]]
      [  if Scenario =  "Nine-center grid-like city" [
           ask locations [  if (xcor = -1 * int(grid-size / 4) * scale and ycor = 0) or ( xcor =  int(grid-size / 4) * scale and ycor = 0) or (xcor = 0 and ycor = -1 * int(grid-size / 4) * scale) or (xcor  = 0 and ycor = int(grid-size / 4) * scale)  
           or (xcor = -1 * int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or  (xcor =  int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or ( xcor  = 0 and ycor = 0) 
           or  (xcor =  int(grid-size / 4) * scale and ycor = int(grid-size / 4) * scale) or (xcor =  int(grid-size / 4) * scale and ycor = -1 * int(grid-size / 4) * scale) or (xcor =  -1 * int(grid-size / 4) * scale and ycor = -1 * int(grid-size / 4) * scale)
          [ set color red  set size 1] ]]]]]
  
  
  construct-connectedList_for_locations
  
end

to setup-skyway-scenario
   clear-all
   clear-patches
   clear-drawing
   clear-all-plots
   clear-output
    set-default-shape buildings "circle"
    set matchratio-list []
    set infinity 999999  ; just set a large value
    ask patches [set pcolor white]
    set nodes-dataset gis:load-dataset "centroids_new2_SpatialJoin7.shp"
    set skyways-dataset  gis:load-dataset "downtown_skyways2.shp"
    set block-dataset  gis:load-dataset "potentialblocks.shp"
     set completelinks-dataset  gis:load-dataset "complete_downtown_network.shp"
    ;gis:set-world-envelope ((gis:envelope-of skyway-dataset))
    gis:set-world-envelope (gis:envelope-union-of (gis:envelope-of nodes-dataset) (gis:envelope-of skyways-dataset) (gis:envelope-of block-dataset) (gis:envelope-of completelinks-dataset) )
    
    ; show downtown street   
    ifelse show_downtown_streets 
    [ import-drawing "environment3.jpg" ]
    [ clear-drawing  ]   
                                
    display-buildings
    import-skyways
    import-completelinks
    construct-connectedList
    
    ifelse show_actual_skyways
    [ ask skyways [set color black show-link] ]
    [ ask skyways [set color black hide-link]]
    

end 



; the skyway data imported is a turtle, not a link dataset
to import-skyways
   ask skyways [die]
   
   foreach gis:feature-list-of skyways-dataset
   [
      let o gis:property-value ? "ORIGIN"
      let d gis:property-value ? "DESTIN"
      
      ask building (o - 1) [    
      create-skyway-with building ( d - 1) 
      ;mark the first link that was built
      if firstconnectyear = 0 or firstconnectyear >  gis:property-value ? "YEAR"
      [ set firstconnectyear (gis:property-value ? "YEAR" )]   
      ] 
      
      ask building ( d - 1) [ 
       if firstconnectyear = 0 or firstconnectyear >  gis:property-value ? "YEAR"
      [ set firstconnectyear (gis:property-value ? "YEAR" )]]
      
      ask skyway (o - 1) (d - 1)  [   hide-link
                                      set year gis:property-value ? "YEAR"  
                                      set len gis:property-value ? "length" ]]  
end 


;to display-actual-skyway
;  if Scenario = "Minneapolis skway"
 ; [ ask skyways [set color black show-link]]
;end

;to hide-actual-skyway
;   ask skyways [set color black hide-link]
;end

to display-buildings
   ask buildings [die]  
   ask buildings [  set accessiblity 0  set marginalProfitlist [] set distance-from-other-buildings [] 
       set shortest-path-nodes []  set nodelist [] set connectedList []  set space-list []
       set connect false ]
   
   foreach gis:feature-list-of nodes-dataset [ 
      let centroid gis:location-of gis:centroid-of ?
      if not empty? centroid [  
        create-buildings 1   [ 
            ;set employee em
            ;set pcolor red
             set space-list []
            gis:set-drawing-color red
            gis:fill ? 3.0
            set xcor item 0 centroid
            set ycor item 1 centroid
            set size 0
            ; import the property value from "Employee"
            set employee gis:property-value ? "EMP05"
            set blockID  gis:property-value ?  "BLOCKID"   
            set space-list lput (gis:property-value ?  "space1962") space-list  
            set space-list lput gis:property-value ?  "space1963" space-list  
            set space-list lput gis:property-value ?  "space1964" space-list  
            set space-list lput gis:property-value ?  "space1965" space-list  
            set space-list lput gis:property-value ?  "space1966" space-list  
            set space-list lput gis:property-value ?  "space1967" space-list  
            set space-list lput gis:property-value ?  "space1968" space-list  
            set space-list lput gis:property-value ?  "space1969" space-list  
            set space-list lput gis:property-value ?  "space1970" space-list  
            set space-list lput gis:property-value ?  "space1971" space-list 
            set space-list lput gis:property-value ?  "space1972" space-list  
            set space-list lput gis:property-value ?  "space1973" space-list  
            set space-list lput gis:property-value ?  "space1974" space-list              
            set space-list lput gis:property-value ?  "space1975" space-list              
            set space-list lput gis:property-value ?  "space1976" space-list           
            set space-list lput gis:property-value ?  "space1977" space-list              
            set space-list lput gis:property-value ?  "space1978" space-list             
            set space-list lput gis:property-value ?  "space1979" space-list              
            set space-list lput gis:property-value ?  "space1980" space-list              
            set space-list lput gis:property-value ?  "space1981" space-list              
            set space-list lput gis:property-value ?  "space1982" space-list  
            set space-list lput gis:property-value ?  "space1983" space-list  
            set space-list lput gis:property-value ?  "space1984" space-list  
            set space-list lput gis:property-value ?  "space1985" space-list  
            set space-list lput gis:property-value ?  "space1986" space-list  
            set space-list lput gis:property-value ?  "space1987" space-list  
            set space-list lput gis:property-value ?  "space1988" space-list                 
            set space-list lput gis:property-value ?  "space1989" space-list                
            set space-list lput gis:property-value ?  "space1990" space-list                 
            set space-list lput gis:property-value ?  "space1991" space-list             
            set space-list lput gis:property-value ?  "space1992" space-list      
            set space-list lput gis:property-value ?  "space1993" space-list              
            set space-list lput gis:property-value ?  "space1994" space-list              
             set space-list lput gis:property-value ?  "space1995" space-list     
            set space-list lput gis:property-value ?  "space1996" space-list               
            set space-list lput gis:property-value ?  "space1997" space-list     
            set space-list lput gis:property-value ?  "space1998" space-list                        
            set space-list lput gis:property-value ?  "space1999" space-list                          
            set space-list lput gis:property-value ?  "space2000" space-list        
            set space-list lput gis:property-value ?  "space2001" space-list     
            set space-list lput gis:property-value ?  "space2002" space-list   ]]]    
   
end 

  
to import-completelinks
  ask completelinks [die] 
  foreach gis:feature-list-of completelinks-dataset
  [
     let ori gis:property-value ? "ORIGIN"
     let dest gis:property-value ? "DESTIN"
     ask building (ori - 1) [ create-completelink-with building (dest - 1) ]    
     ask completelink (ori - 1) ( dest - 1) [hide-link]
    ]  
end  

to construct-connectedList
  
     let node one-of buildings
     let buildingnum count  buildings
     let i 0
     while [ i < buildingnum ]
     [
        set node building i
        ;; identify nodes without potential to connect
        ifelse i = 91 or i = 87 or i = 88 or i = 90 or i = 77 or i = 93 or i = 85 or i = 84 or i = 79  or i = 94 or i = 100 or 
        i = 103 or i = 83 or i = 104 or i = 82 or i = 80 or i = 96 or i = 81 or i = 101 or i = 97 or i = 89 or i = 92 
        or i = 98 or i = 99 or i = 102 
        [ ask node  [set connectedList []] ]
        ;; the rest is the completelink neighbors 
        [  ask node [set connectedList [who] of completelink-neighbors] ] 
    
        set i i + 1  ] 
      ask building 10 [set connectedList remove 82 connectedList]
      ask building 14 [set connectedList remove 82 connectedList]
      ask building 19 [set connectedList remove 82 connectedList]
      ask building 64 [set connectedList remove 82 connectedList]
      
      ask building 19 [set connectedList remove 101 connectedList]
      ask building 30 [set connectedList remove 101 connectedList]
      ask building 37 [set connectedList remove 101 connectedList]
      ask building 31 [set connectedList remove 101 connectedList]    
      
      ask building 44 [set connectedList remove 83 connectedList] 
      ask building 50 [set connectedList remove 83 connectedList] 
      ask building 54 [set connectedList remove 83 connectedList] 
      ask building 68 [set connectedList remove 83 connectedList] 
      ;ask buildings [set connectedList [self] of completelink-neighbors]
      ;output-show [connectedList] of building 91
end


to construct-connectedList_for_locations
     let node one-of locations
     ask locations [set connectedList []]
     let locationnum count locations
     let i 0  
     while [i < locationnum]
     [ 
         set node location i
         let j 0
         while [ j < locationnum]
         [
            if [distance node] of location j = scale
            [ ask node [ set connectedList lput j connectedList ] ] 
            set j j + 1  ] 
         ;ask node [output-show connectedList]
         set i i + 1 
         ]
  
end
  


to go
   
    Setup  
   
    ifelse Scenario = "Minneapolis skway"
    [ ask simulinks [set color red] runSkwaynetwork ]
    [ ask roads [set color red] runGridcitynetwork]
    
  
end 

to runSkwaynetwork
   let i 0
   let previouslinks 0  
    while [ i < rounds ]
   [
      ifelse i < 40
      [ ask buildings [set space (item i space-list) ]  ] 
      [ask buildings [set space last space-list ] ]
      begin-build-skyways
      plot-nodes
      set i i + 1 ]
end

to runGridcitynetwork
  let i 0
  while [ i < rounds ]
  [
     begin-build-gridnetwork
     plot-nodes
     set i i + 1  
  ]
  
end 


to begin-build-skyways
    let i 0
    let p 0
    let t 0
    let dist 0
    let id 0
    let connectNode 0
    let tickIndex false
    set sequence []
    let node-count count buildings
    ask buildings [set accessiblity 0  set marginalProfitlist [] set distance-from-other-buildings [] set shortest-path-nodes  []  set nodelist [] set matchratio-list []]
    
    ask buildings [
      initialize-distances-among-buildings
      find-building-path-lengths [who] of self
      let accessiblity_no_newlink accessiblity 
      let m 0
      while [m < length connectedlist]
      [
           set t item m connectedList
           if [ simulink-neighbor? building t ] of self  = false ;and id != t
           [ create-simulink-with building t ;set color red 
             ;output-show "enter here"
             find-distance-to-adjacent-connected-buildings [who] of self
             find-building-path-lengths [who] of self
             let cost ( distance (building t) * unitedgecost )
             set marginalProfitlist lput (accessiblity - accessiblity_no_newlink - cost) marginalProfitlist
             output-show "accessiblity"
             output-show accessiblity
             set nodelist lput t nodelist
             ask simulink ([who] of self ) t [die]
             ;ask my-simulinks with [other-end = t] [die]
           ] 
             
        set m m + 1  ]
      
      if marginalProfitlist != [] and nodelist != []
      [
         if  (max marginalProfitlist) > 0
         [
            let maxvalue (max marginalProfitlist)
            set p (position maxvalue marginalProfitlist) 
            let node1 item p nodelist
            create-simulink-with building node1 [set color red]
            set connect true
            ask building node1 [set connect true]]]]        
    
    tick   
end


to initialize-distances-among-buildings
  
 ;; initlialize the initialize-distance-set for all buildings
  ask buildings [set distance-from-other-buildings [] ]
  set infinity 9999999999
  let i 0
  let j 0
  let k 0
  let node1 one-of buildings
  let node2 one-of buildings
  let node-count count buildings
  ;; initialize the distance lists
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 building i
      set node2 building j
      ;; zero from a node to itself
      ifelse i = j
      [ ask node1 [ set distance-from-other-buildings lput 0 distance-from-other-buildings ]]
      [
      
        ;; if two nodes are connected, set the distance to be zero because there is no need to build it again;;
        ;; although in some other cases we might want to use another variable to indicate them
        
          ;[ link-neighbor? node1 ] of node2 
         ifelse  [ simulink-neighbor? node1 ] of node2 = false
         [
            ask node1 [  set distance-from-other-buildings lput infinity distance-from-other-buildings ]]
         [
            ask node1 [  set distance-from-other-buildings lput (distance node2) distance-from-other-buildings ]]]
      set j j + 1  ]
      set i i + 1 ]
 
  

end 


to find-building-path-lengths [m]
 ;; initialize 
   let i 0
   let j 0
   let v 0
   let u 0
   let temp 0
   let newdist 0
   let node-count count buildings
   set prev [] ;; the precedent of each node
   let index [] ; an index indicating whether each node has been added to the graph (true) or not added to the graph (falso)
   
   ;; initialization: set every distance to INFINITY until we discover a path 
   while [i < node-count]
   [
      ;;set distance-from-other-turtles lput (item i [distance-from-immediate-nodes] of turtle m) distance-from-other-turtles 
      ;; keep track of whether the node has been searched or not. 
      set index lput false index
      ;; if the distance infinity then put 0 as the initial value, otherwise put the distance
      ifelse item i [distance-from-other-buildings] of building m = infinity 
         [set prev lput 0 prev]
         [set prev lput m prev]
      set i i + 1
   ]   
 
   ;;output-show prev
      ;; distance for the source m to the source m is defined to be zero
   ;;set distance-from-other-turtles replace-item m distance-from-other-turtles 0 
   
   set index replace-item m index true  ;; having been searched

   ;; this loop corresponds to sending out the explorers walking the paths, where
   ;; the step of picking "the vertex, v, with the shorest path to s" corresponds
   ;; to an explorer arriving at an unexplored vertex
   set i 0
   while [i < node-count ]
   [
      ;;find the vertex v in set-of-nodes with smallest dist[] []
      
      set temp infinity 
      set u m 
      set j 0
      
      while [j < node-count]
      [ 
         if (item j index = false) and (item j [distance-from-other-buildings] of turtle m < temp )
         [ 
             set u j
             set temp (item j [distance-from-other-buildings] of turtle m)
         ]
         set j j + 1
      ]
      
      set index replace-item u index true
      
      set j 0
     
      while [ j < node-count]
      [  
          if  ( item j index = false ) and  (item j [distance-from-other-buildings] of turtle u < infinity)
          [
     
             set newdist ( item u [distance-from-other-buildings] of turtle m + item j [distance-from-other-buildings] of turtle u )    
             if newdist < item j [distance-from-other-buildings] of turtle m
             [
                
                ; set [distance-from-other-turtles] of turtle m replace-item j [distance-from-other-turtles] of turtle m newdist
                ;ask turtle m [ set distance-from-other-turtles  j [distance-from-other-turtles] of turtle m newdist ]
                ask building m [set distance-from-other-buildings replace-item j [distance-from-other-buildings] of building m newdist ]
                
                set prev (replace-item j prev u)
             ]
          ]
         
          set j j + 1
      ]
      
      set i i + 1
    ]  
  
    ; output-show prev
    
   ;; calculate the profit of the whole network for trutle m 
    set j 0
    let revenue 0

   ask building m [

      while [j < node-count]
      [
         if item j distance-from-other-buildings != infinity and item j distance-from-other-buildings > 0
         [
            ;; identify the id of node
            ;; the value of a node is proportional to the number of emploe=yee in that node
           set revenue revenue + unitbenefit * ([space] of building m / 240) * (item j distance-from-other-buildings) ^ (- delta) ]  
           set j j + 1 ]
           set accessiblity revenue ]  
end


to find-distance-to-adjacent-connected-buildings [id]
  
  ask building id [set distance-from-other-buildings [] ]
  let j 0
  let node-count count buildings
  
  while [j < node-count]
  [
      ifelse id = j
      [
        ask building id [ set distance-from-other-buildings lput 0 distance-from-other-buildings ]
      ]
      [
          ifelse  [ simulink-neighbor? building id ] of building j = false
          [
             ask building id  [  set distance-from-other-buildings lput infinity distance-from-other-buildings ] ]
          [
             ask building id   [  set distance-from-other-buildings lput (distance building j) distance-from-other-buildings ]  ] ]  
    
      set j j + 1 ]

end


to begin-build-gridnetwork
   let i 0
    let j 0
    let k 0
    let p 0
    let s 0
    let t 0
    let dist 0
    let id 0
    let connectNode 0
    set sequence []
    let node-count count locations ; count locations in the grid-like city
    ask locations [set accessiblity 0  set marginalProfitlist [] set distance-from-other-locations [] set shortest-path-nodes  []  set nodelist [] set matchratio-list []]
    
    ask locations [
      initialize-distances-among-locations
      find-location-path-lengths [who] of self
      let accessiblity_no_newlink accessiblity 
      let m 0
      ;output-show distance-from-other-locations
      while [m < length connectedlist]
      [
           set t item m connectedList
           if [ road-neighbor? location t ] of self  = false ;and id != t
           [ create-road-with location t ;set color red 
             find-distance-to-adjacent-connected-locations [who] of self
             output-show "distance from other locations" output-show distance-from-other-locations
             find-location-path-lengths [who] of self
             set marginalProfitlist lput (accessiblity - accessiblity_no_newlink - newedgecost) marginalProfitlist
             output-show "margial profit" 
             output-show (accessiblity - accessiblity_no_newlink - newedgecost)
             set nodelist lput t nodelist
             ask road ([who] of self ) t [die]
           ] 
             
        set m m + 1  ]
      
      if marginalProfitlist != [] and nodelist != []
      [
         if  (max marginalProfitlist) > 0
         [
            let maxvalue (max marginalProfitlist)
            set p (position maxvalue marginalProfitlist) 
            let node1 item p nodelist
            create-road-with location node1 [set color red]
            set connect true
            ask location node1 [set connect true]]]]        
    
    tick 
end

to initialize-distances-among-locations
   set infinity 9999999999
   ask locations  [set distance-from-other-locations [] ]
   let i 0
   let j 0
   let k 0
   let node1 one-of locations
   let node2 one-of locations
   let node-count count locations
  while [i < node-count]
  [
    set j 0
    while [j < node-count]
    [
      set node1 location i
      set node2 location j
      ;; zero from a node to itself
      ifelse i = j
      [ ask node1 [ set distance-from-other-locations lput 0 distance-from-other-locations ]]
      [

         ifelse  [ road-neighbor? node1 ] of node2 = false
         [
            ask node1 [  set distance-from-other-locations lput infinity distance-from-other-locations ]]
         [
            ask node1 [  
               let dist (distance node2)
               ;output-show "distance"  output-show  dist 
               set distance-from-other-locations lput dist distance-from-other-locations ]]]
      set j j + 1  ]
      set i i + 1 ]   
  
   ;ask locations [output-show distance-from-other-locations ]
end 


; change a name for that..
to find-location-path-lengths [m]
   let i 0
   let j 0
   let v 0
   let u 0
   let temp 0
   let newdist 0
   let node-count count locations
   set infinity 9999999999
   set prev [] ;; the precedent of each node
   let index [] ; an index indicating whether each node has been added to the graph (true) or not added to the graph (falso)
   while [i < node-count]
   [ 
      set index lput false index
      ;; if the distance infinity then put 0 as the initial value, otherwise put the distance
      ifelse item i [distance-from-other-locations] of location m = infinity 
         [set prev lput 0 prev]
         [set prev lput m prev]
      set i i + 1
   ]
   
   set index replace-item m index true  ;; having been searched
   set i 0
   while [i < node-count ]
   [

      set temp infinity 
      set u m 
      set j 0
      
      while [j < node-count]
      [ 
         if (item j index = false) and (item j [distance-from-other-locations] of location m < temp )
         [ 
             set u j
             set temp (item j [distance-from-other-locations] of location m)
         ]
         set j j + 1
      ]
      
      set index replace-item u index true
      
      set j 0
     
      while [ j < node-count]
      [  
          if  ( item j index = false ) and  (item j [distance-from-other-locations] of location u < infinity)
          [
     
             set newdist ( item u [distance-from-other-locations] of location m + item j [distance-from-other-locations] of location u )    
             if newdist < item j [distance-from-other-locations] of turtle m
             [
   
                ask location m [set distance-from-other-locations replace-item j [distance-from-other-locations] of location m newdist ]
                
                set prev (replace-item j prev u)
             ]
          ]
         
          set j j + 1
      ]
      
      set i i + 1
    ]  
   
   ;ask location m 
   ;[output-show "location m"
   ; output-show distance-from-other-locations]
  
   ;; calculate the profit of the whole network for location
    set j 0
    let revenue 0
    ask location m [
    while [j < node-count]
      [
         if item j distance-from-other-locations != infinity and item j distance-from-other-locations > 0
         [ 
           
             ifelse Scenario = "Single-center grid-like city"
             [ 
                ifelse  [xcor] of location j = 0 and [ycor] of location j  = 0    
                [ set revenue revenue +  w_center * (item j distance-from-other-locations ) ^ (- delta)]
                [ set revenue revenue +  w * (item j distance-from-other-locations) ^ (- delta) ] ]
             [
                ifelse Scenario = "Two-center grid-like city"
                [
                    ifelse ( [xcor] of location j = -1 * int(grid-size / 4) * scale  and [ycor] of location j = 0) or ( [xcor] of location j = int(grid-size / 4) * scale and [ycor] of location j = 0)
                    [ set revenue revenue +  w_center * (item j distance-from-other-locations ) ^ (- delta)]
                    [ set revenue revenue +  w * (item j distance-from-other-locations) ^ (- delta) ] ]
                [
                    ifelse Scenario = "Four-center grid-like city"
                    [ 
                       ifelse ([xcor] of location j = -1 * int(grid-size / 4) * scale and [ycor] of location j = 0) or ( [xcor] of location j =  int(grid-size / 4) * scale and [ycor] of location j = 0) 
                       or ([xcor] of location j = 0 and [ycor] of location j = -1 * int(grid-size / 4) * scale) or ([xcor] of location j  = 0 and [ycor] of location j = int(grid-size / 4) * scale)  
                       [ set revenue revenue +  w_center * (item j distance-from-other-locations ) ^ (- delta)]
                       [ set revenue revenue +  w * (item j distance-from-other-locations) ^ (- delta) ] ]
                     [
                       if Scenario =  "Nine-center grid-like city"
                       [
                          ifelse ([xcor] of location j  = -1 * int(grid-size / 4) * scale and [ycor] of location j  = 0) or 
                            ([xcor] of location j  =  int(grid-size / 4) * scale and[ ycor] of location j  = 0) or
                            ([xcor] of location j  = 0 and [ycor] of location j  = -1 * int(grid-size / 4) * scale) or 
                            ([xcor] of location j  = 0 and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ([xcor] of location j = -1 * int(grid-size / 4) * scale and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ([xcor] of location j  =  int(grid-size / 4) * scale and [ycor] of location j  = int(grid-size / 4) * scale) or 
                            ( [xcor] of location j  = 0 and [ycor] of location j  = 0) or
                            ([xcor]  of location j =  int(grid-size / 4) * scale and [ycor]  of location j = int(grid-size / 4) * scale) or 
                            ([xcor] of location j =  int(grid-size / 4) * scale and [ycor] of location j = -1 * int(grid-size / 4) * scale) or 
                            ([xcor]  of location j  =  -1 * int(grid-size / 4) * scale and [ycor] of location j = -1 * int(grid-size / 4) * scale)
                            [ set revenue revenue +  w_center * (item j distance-from-other-locations ) ^ (- delta)]
                            [ set revenue revenue +  w * (item j distance-from-other-locations) ^ (- delta) ]]]]]]
           set j j + 1 ]
           set accessiblity revenue
           output-show "accessibility"
           output-show accessiblity]  

end


to find-distance-to-adjacent-connected-locations [id]
  
  ask location id [set distance-from-other-locations [] ]
  let j 0
  let node-count count locations
  
  while [j < node-count]
  [
      ifelse id = j
      [
        ask location id [ set distance-from-other-locations lput 0 distance-from-other-locations ]
      ]
      [
          ifelse  [ road-neighbor? location id ] of location j = false
          [ ask location id  [  set distance-from-other-locations lput infinity distance-from-other-locations ] ]
          [ ask location  id   [  set distance-from-other-locations lput (distance location j) distance-from-other-locations ]  ] ]  
    
      set j j + 1 ]
  
end 

; plot number of connected buildings or locations 
to plot-nodes

  set-current-plot "Num of connected nodes"  
  ifelse Scenario = "Minneapolis skway"
  [ set-plot-y-range 1 (count buildings + 10)
    plot count buildings with [count simulink-neighbors > 0 ] ]
  [  set-plot-y-range 1 (count locations + 10)
    plot count locations with [count road-neighbors > 0 ] ]
  
  set-current-plot "Num of links"  
  ifelse Scenario = "Minneapolis skway"
  [ plot count simulinks ]
  [ plot count roads ]
 
 
  set-current-plot "Meshedness"
  ifelse Scenario = "Minneapolis skway"
   [
      let m count simulinks
      let n count buildings
      plot (m - n + 1)/(2 * n - 5)
   ]
   [ let m count roads
     let n count locations
     plot (m - n + 1)/(2 * n - 5)
   ]
   
   
  ; calculate the average number of connections in each round  
  set-current-plot "Average degree of connections"
  ifelse Scenario = "Minneapolis skway"
  [  let dg 0
     let max-degree max [count simulink-neighbors] of buildings
     set-plot-y-range 1 (max-degree + 1) 
     ask buildings [set dg ( dg + count simulink-neighbors)]
     plot dg / (count buildings with [count simulink-neighbors > 0 ] )
  ]
  [
     let max-degree max [count road-neighbors] of locations
     set-plot-y-range 1 6 
     let dg 0
     ask locations [ set dg ( dg + count road-neighbors)]
     if count roads > 0 [ plot dg / count locations with [count road-neighbors > 0 ] ] 
  ] 
   
  
  set-current-plot "Degree Distribution"
  plot-pen-reset
  ifelse Scenario = "Minneapolis skway"
  [  let max-degree max [count simulink-neighbors] of buildings
     set-plot-x-range 1 (max-degree + 1)  ;; + 1 to make room for the width of the last bar
       histogram [count simulink-neighbors] of buildings with [count simulink-neighbors > 0 ]]
  [ let max-degree max [count road-neighbors] of locations
     set-plot-x-range 1 6  ;; + 1 to make room for the width of the last bar
       histogram [count road-neighbors] of locations with [count road-neighbors > 0 ] ]  
  
  
  set-current-plot "Degree Distribution (log-log)"
  plot-pen-reset  ;; erase what we plotted before
  ;; the way we create the network there is never a zero degree node,
  ;; so start plotting at degree one
  ifelse Scenario = "Minneapolis skway"
  [  let degree 1
     let max-degree max [count simulink-neighbors] of buildings
     while [degree <= max-degree]
     [let matches buildings with [count simulink-neighbors = degree]
     if any? matches
     [ plotxy log degree 10
               log (count matches) 10 ]
      set degree degree + 1] ]
 [  let degree 1
     let max-degree max [count road-neighbors] of locations
     while [degree <= max-degree]
     [let matches locations with [count road-neighbors = degree]
     if any? matches
     [ plotxy log degree 10
               log (count matches) 10 ]
      set degree degree + 1]]  
  
  
   
  

end
@#$#@#$#@
GRAPHICS-WINDOW
587
10
1209
653
25
25
12.0
1
10
1
1
1
0
1
1
1
-25
25
-25
25
0
0
1
ticks

CHOOSER
75
49
281
94
Scenario
Scenario
"Single-center grid-like city" "Two-center grid-like city" "Four-center grid-like city" "Nine-center grid-like city" "Minneapolis skway"
4

SLIDER
62
334
269
367
Grid-size
Grid-size
1
25
9
2
1
NIL
HORIZONTAL

SLIDER
61
401
267
434
Scale
Scale
1
4
4
0.5
1
NIL
HORIZONTAL

SLIDER
69
187
274
220
delta
delta
0
3.0
0.68
0.01
1
NIL
HORIZONTAL

SLIDER
330
534
539
567
unitbenefit
unitbenefit
1
10
1.45
0.05
1
NIL
HORIZONTAL

SLIDER
329
465
537
498
unitedgecost
unitedgecost
10
500
330
10
1
NIL
HORIZONTAL

TEXTBOX
1197
88
1347
106
NIL
11
0.0
1

SLIDER
61
464
266
497
newedgecost
newedgecost
0
1000
542
1
1
NIL
HORIZONTAL

SLIDER
59
533
268
566
w_center
w_center
0
2000
814
1
1
NIL
HORIZONTAL

BUTTON
815
665
1031
717
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
25
20
175
38
Scenario setting
14
15.0
0

TEXTBOX
73
169
223
187
Distance decay parameter
11
0.0
1

PLOT
1231
45
1478
195
Num of connected nodes
Rounds
Count
0.0
10.0
0.0
100.0
true
false
PENS
"default" 1.0 1 -2674135 true

TEXTBOX
1235
11
1461
41
Network topological measures
15
15.0
1

SWITCH
335
337
532
370
show_downtown_streets
show_downtown_streets
0
1
-1000

TEXTBOX
21
120
171
139
Parameters
15
15.0
1

TEXTBOX
38
144
188
162
Common parameters
12
104.0
1

TEXTBOX
29
292
305
322
Parameters in the Grid-like City model
13
104.0
1

TEXTBOX
66
316
216
334
Number of rows/columns
11
0.0
1

TEXTBOX
66
381
282
409
Distance between rows/columns
11
0.0
1

TEXTBOX
64
445
214
463
Cost of an edge
11
0.0
1

TEXTBOX
63
512
278
540
Value of a centeral location (red)
11
0.0
1

TEXTBOX
60
576
300
604
Value of an ordinary location (green)
11
0.0
1

SLIDER
56
594
264
627
w
w
0
2000
410
1
1
NIL
HORIZONTAL

TEXTBOX
298
293
608
341
Paramters in the Minneapolis skyway model
13
104.0
1

TEXTBOX
337
318
548
346
Show downtown streets (google map)
11
0.0
1

TEXTBOX
335
444
540
472
Cost per unit length of an edge
11
0.0
1

TEXTBOX
336
515
556
543
Value of accessing an employee
11
0.0
1

TEXTBOX
1488
763
1758
805
Copyright: Arthur Huang and David Levinson\n                                       2012
11
0.0
1

SLIDER
71
246
272
279
rounds
rounds
0
50
47
1
1
NIL
HORIZONTAL

TEXTBOX
71
230
221
248
Number of rounds
11
0.0
1

SWITCH
333
396
532
429
show_actual_skyways
show_actual_skyways
1
1
-1000

BUTTON
591
667
788
718
NIL
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

PLOT
1506
218
1748
368
Degree Distribution
Degree
Num of nodes
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

PLOT
1505
396
1742
548
Degree Distribution (log-log)
Degree (log)
# of nodes (log)
0.0
0.3
0.0
0.3
true
false
PENS
"default" 1.0 0 -16777216 true

PLOT
1507
45
1748
195
Num of links
Rounds
# of links
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

PLOT
1237
397
1473
550
Meshedness
Rounds
Meshedness
0.0
10.0
0.0
1.0
true
false
PENS
"default" 1.0 0 -16777216 true

PLOT
1237
219
1475
369
Average degree of connections
Rounds
Averge degrees of connections
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

TEXTBOX
1240
562
1490
618
 Meshedness: ( m - n + 1 ) / ( 2n - 5)\n m: number of links\n n: number of vertices\nGreater meshedness indicates more grid-like
11
0.0
1

@#$#@#$#@
WHAT IS IT?
-----------
This applet models the growth of networks in several scenarios such as an artifical grid-like city and the Minneapolis skyway system. The philosophy inherent in these models is that accessibility affects network growth and vertice versa. Different values of accessibility at individual locations may lead to different network structures. 

HOW IT WORKS
------------
A sky assumption in these models is that the network is built from bottom to up, driven by individual investors' intention to maximize their benefits. The models in the five scenarios have the same mechanism. Here let's take the skyway scenario as an example. 

The edges of the network are called segments, and the vertices are buildings. The edges of the network are skyway segments, and the vertices are buildings. Let's assume the value of accessibility for building owner i to build a new segment k in round t equals:

A_i(k,t)= \sum_{j=1}^J w * beta_{j,t} *d_{ij,t}^{- delta}

where d_{ij,t} is the shortest network distance between vertices i and j. delta is a distance decay parameter, indicating that a longer travel path lowers the value of accessibility. $w$ is the value of accessing one employee. beta_{j, t} represents the total number of employees in building $j$ in iteration t, which is assumed to be proportional to the area of office space in building j. Since the employees' data are not available for verification, this assumption is only approximately true, but it serves as a plausible start. In addition, since the office space of a building in reality evolved over time, in simulation each iteration's beta_{j, t} is updated using the office space data for building j in a corresponding year. 

For building owner i, the incentive to build segment k is measured as the increased value of accessibility due to this new segment. The disincentive is the cost of building and maintaining segment $k$ which is presumably proportional to its length. The marginal benefit for building owner $i$ to build segment k is the difference between the incentive and disincentive, which can be described as:

Delta p_i (k, t) = A_i (k, t) - A_i (k, t-1) - c * l_k

where l_k is the length of segment k and c is the unit cost of segment k. Among all possible segments to be built, building owner i selects the segment that provides the highest marginal benefit. If the highest marginal benefit is greater than zero, a segment will be built; otherwise no segment will be built. This is thus a locally selfish, myopic optimization, maximizing short-term benefit for the building owner himself. In deciding the segment candidates for each building owner, we rule out the segments which cannot be built because of specific uses of certain buildings (e.g., government administrative building). 

By setting different values of the paramters of the network, the users can test how different values of parameters affect the network structure. 

To quantify the similarity between the modeled network and the actual network, we propose a matching index which rewards the matched segments and penalizes the mismatched segments. It equals:

rho = \frac{alpha}{M} - (1- \frac{alpha}{T})

where alpha is the number of simulated skyway segments matching the actual network; M is the total number of simulated skyway segments; T indicates the total number of actual skyway segments. The higher rho is, the more similar the generated network is to the actual network. 


HOW TO USE IT
-------------
There are four scenarios that can be tested: a sigle-center grid-like city, a two-center grid-like city, a four-center grid-like city, a nine-center grid-like city , and the Minneapolis skyway system. After selecting the scenario from the Scenario Panel, click "Setup" button to intitate the designated pattern. 

Two variables are common in all four scenarios: distance decay parameter (beta) and the unit cost of segment construction. Distance decay parameter is the exponential term of the network distance between two locations in the accessibility function. When used in the function, the actual value is the negative form of the input, which means that longer travel distance decreases the value of accessibility. The unit cost of segment construction are defined slightly different for the grid-like model and the skyway model. In the grid-like model, since all the links have the same length, the unit cost of segment construction represents the cost of building a link; however, in the Minneapolis skyway model, the unit cost of segment construction represents the cost of bulindg a link per meter, considering the fact that the lengths of the segments are different. 

The grid-like city models and the Minneapolis skyway model also have different input variables. In the grid-like city models, users can set up grid size, scale, the value of accessibility of a center, and the value of accessibility of an ordinary location. Grid size indicates the number of locations in a row or column. The scale variable can change the relative distance of adjacent locations. Since the unit cost of builging a link in the grid-like city models is only set by users, the scale variable does not affect the outputs of the models, but only serves to help visually present the outputs. In the skyway model, we assume all buildings have the same value of accessibility per employee, which is indicated by unitbenefit_p. 


THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


OTHER FEATURES
----------------
In the skyway network scenario, users can select the google map of downtown Minneapolis as the background by clicking "change background", and clear the background by clicking "clear background".

CREDITS AND REFERENCES
----------------------
The details about the models can be found in the following two papers:

Levinson, D. and Huang, A. (2012) A Positive Theory of Network Connectivity. Environment and Planning B (in press) URL: http://nexus.umn.edu/Papers/TheoryOfConnectivity.pdf

Huang, A. and Levinson, D. (2012)  The structure and dynamics of a skyway network. The European Physical Journal: Speical issue (in press) 
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
