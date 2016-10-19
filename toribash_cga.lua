-- Static variables and global variables
local POP_SIZE = 10
local NUM_OF_JOINT = 22
local loadPrev = false              --load population stored in file from previous run
local fileExists = false          --don't want to append to non existent file
local round = 0 
local bestFile = "best.txt"       --stores the best of the current run
local popFile = "population.txt"  --stores the current population
local moved = false               --only allows 1 move per individual
local initialised = false         --checks if population has already been initialised
local individual = {}              --tmp individual storage
local bestPop = {}                --stores the best o the population
local current_indiv = 1           --tracks current individual
local population = {}             --array storing individuals
local truncSize = 0.3             --% of population that gets through round
local eliteSize = 2               --no. of individuals that survive each round intact
local chromeLength = 22            --20 values for the joints + 2 for the grip
local jointVals = {}
local bestIndiv = {}
local probabilityVector = {}
local popSize = 10               --how many individuals in your population
math.randomseed(os.time())

-- initialising best individual
local tmpVals={}
for i = 1 , chromeLength do
   table.insert(tmpVals,1)
   bestIndiv = {fitness = 0, jointVals = tmpVals}
end

local function get_fitness()
   tori_score = math.floor(get_player_info(1).injury)
   uke_score = math.floor(get_player_info(0).injury)
   fitness = tori_score - uke_score
   return fitness
end

--utility methods
local function open_file(filename)
        local oldinput = io.input()
   io.input(filename)
   local file = io.input()
   io.input(oldinput)
   return file
     end

local function write_file(filename)
   local oldoutput = io.output()
   io.output(filename)
   local file = io.output()
   io.output(oldoutput)
   return file
     end

local function append_to_file(filename,string)
   local tmpInput = open_file(filename)
   local lines = {}
   
   while true do
        line = tmpInput:read("*l")
        if not line then break end
   table.insert(lines,line)
   end
   table.insert(lines,string)
    
   local tmpOutput = write_file(filename)
   for i=1,table.getn(lines) do
      tmpOutput:write(lines[i],"\n")
   end
   tmpInput:close()
   tmpOutput:close()
end

local function print_pop(pop)
   for i=1,table.getn(pop) do 
      print(i.." fitness "..pop[i].fitness,"value: "..table.concat(pop[i].jointVals,",")) 
   end
end

local function write_pop()
   currentPop = write_file(popFile)
   for i=1,table.getn(population) do
      currentPop:write(population[i].fitness,":",table.concat(population[i].jointVals,","),"\n") 
   end
   currentPop:close()
end

local function sort_pop()
   table.sort(population,function(a,b) return a.fitness > b.fitness end)
end

local function check_best()
   if population[1].fitness > bestIndiv.fitness then
      bestIndiv.fitness,bestIndiv.jointVals = population[1].fitness,population[1].jointVals
      print("New best individual: "..bestIndiv.fitness.." move: "..table.concat(bestIndiv.jointVals,","))   
      indivString = bestIndiv.fitness..": "..table.concat(bestIndiv.jointVals,",")
      if loadPrev == false and fileExists == false then
    tmpFile = write_file(bestFile)
    tmpFile:write(indivString.."\n")
    tmpFile:close()
    fileExists = true
      else
    append_to_file(bestFile,indivString)
      end
   else
      population[1].fitness,population[1].jointVals = bestIndiv.fitness,bestIndiv.jointVals
   end
end

local function trunc_selection(pop)
   cutoff = math.floor(table.getn(pop)*truncSize)
   newPop = {}
   for i=1,cutoff do
      individual = {fitness = pop[i].fitness,jointVals =pop[i].jointVals}
      table.insert(newPop,individual)
   end
   return newPop
end

-- Checks if individual a is equal to individual b
local function isEqual(a, b)
   for i = 1, NUM_OF_JOINT do
      if a.jointVals[i] ~= b.jointVals[i] then
         return false
      end
   end
   return true
end

-- Initialize the probability vector
local function initProbVec()
   for i = 1, NUM_OF_JOINT do
      prob = {b1 = 0.25, b2 = 0.5, b3 = 0.75}
      table.insert(probabilityVector, prob)
   end
end

-- Generate one individual based on the probability vector
local function generateIndividual()
   a = {}
   
   for i = 1, NUM_OF_JOINT do
      chance = math.random()
      if chance <= probabilityVector[i].b1 then
         a[i] = 1
      elseif chance > probabilityVector[i].b1 and chance <= probabilityVector[i].b2 then
         a[i] = 2
      elseif chance > probabilityVector[i].b2 and chance <= probabilityVector[i].b3 then
         a[i] = 3
      else
         a[i] = 4
      end
   end

   return a
   
end

-- Compares individuals a and b by their fitness
local function compete(a, b)
   if a.fitness > b.fitness then
      return a, b
   else
      return b, a
   end
end

-- Update the probability vector
local function updateProbVec()
   for i = 1, NUM_OF_JOINT do
      if not isEqual(winner, loser) then
         if winner.jointVals[i] == 1 then
            
            probabilityVector[i].b1 = probabilityVector[i].b1 + 2/POP_SIZE
            if probabilityVector[i].b1 > probabilityVector[i].b2 then
               probabilityVector[i].b2 = probabilityVector[i].b1 + 2/POP_SIZE
            end
            if probabilityVector[i].b1 > probabilityVector[i].b3 then
               probabilityVector[i].b3 = probabilityVector[i].b1 + 2/POP_SIZE
            end

         elseif winner.jointVals[i] == 2 then

            probabilityVector[i].b1 = probabilityVector[i].b1 - 2/(2*POP_SIZE)
            probabilityVector[i].b2 = probabilityVector[i].b2 + 2/(2*POP_SIZE)

            if probabilityVector[i].b2 > probabilityVector[i].b3 then
               probabilityVector[i].b3 = probabilityVector[i].b2 + 2/POP_SIZE
            end

         elseif winner.jointVals[i] == 3 then

            probabilityVector[i].b2 = probabilityVector[i].b2 - 2/(2*POP_SIZE)
            probabilityVector[i].b3 = probabilityVector[i].b3 + 2/(2*POP_SIZE)

            if probabilityVector[i].b3 < probabilityVector[i].b1 then
               probabilityVector[i].b1 = probabilityVector[i].b3 - 2/POP_SIZE
            end
            
         else

            probabilityVector[i].b3 = probabilityVector[i].b3 - 2/POP_SIZE

            if probabilityVector[i].b3 < probabilityVector[i].b2 then
               probabilityVector[i].b2 = probabilityVector[i].b3 - 2/POP_SIZE
            end
            if probabilityVector[i].b3 < probabilityVector[i].b1 then
               probabilityVector[i].b1 = probabilityVector[i].b3 - 2/POP_SIZE
            end
         end
      end
   end
end

-- Checks if the algorithms has already converged
local function checkConverged()
   for i = 1, NUM_OF_JOINT do
      if probabilityVector[i].b1 > 0 and probabilityVector[i].b1 < 1 
         or probabilityVector[i].b2 > 0 and probabilityVector[i].b2 < 1
         or probabilityVector[i].b3 > 0 and probabilityVector[i].b3 < 1
         then
         return false
      end
   end

   return true
end

-- Generate a new population by calling generateIndividual() POP_SIZE times
local function generatePop()

   population = {}
   for i = 1, POP_SIZE do

      individual = {fitness = 0, jointVals = generateIndividual()}
      table.insert(population, individual)
   end
end

local function init_pop()
   initProbVec()
   pop = 1

   population = {}
   for i=1,popSize do 
      valArray ={}
      for i=1,chromeLength do  
    table.insert(valArray,math.random(1,4))
      end
      individual = {fitness = 0,jointVals = valArray}
      table.insert(population,individual)
   end
   initialised = true
end

local function load_pop(fileName) 
   print("loading population from file")
   population ={}
   print_pop(population)
   tmpFile = open_file(fileName)

   for i=1,popSize do
      jVals ={}
      indivString = tmpFile:read("*l")
      jointStart = string.find(indivString,":")+1
      jointString = string.sub(indivString,jointStart)

      for val in jointString:gmatch("%w+") do
        table.insert(jVals,val)
      end
      indiv ={fitness= 0, jointVals = jVals}
      table.insert(population,indiv)
   end
   
   initialised = true
   print_pop(population)
   tmpFile:close()
end

-- Calls the initialization functions
local function init()
   initProbVec()
   pop = 1
end

-- GAME FUNCTIONS!
-- takes an array of joint values and configures tori
local function make_move(valArray)
   jointVals = valArray
   jointIndex = 0
   for k,v in pairs(JOINTS) do
      jointIndex = jointIndex + 1
      set_joint_state(0, v, jointVals[jointIndex])
   end
   set_grip_info(0, BODYPARTS.L_HAND,jointVals[jointIndex+1]%3)
   set_grip_info(0, BODYPARTS.R_HAND,jointVals[jointIndex+2]%3)
end

--This makes the game continuous and initialises population
local function next_turn()
   if initialised == false then
      if loadPrev == true then

         load_pop(popFile)
      else

         init_pop()
      end   
   end
   if moved == false then
      make_move(population[current_indiv].jointVals)
      moved = true
   end
   step_game()
end

--[[
This method runs at the end of the round.
--]]
local function next_game()
   fitness = get_fitness()
   print("indiv:" .. current_indiv .. " fitness: " .. fitness .. " value: " .. table.concat(population[current_indiv].jointVals,","))
   population[current_indiv].fitness = fitness
   moved = false
   round = round + 1   
   echo("Round " .. round .. ", move: " .. current_indiv .. ", fitness:  " .. fitness)
   current_indiv = current_indiv + 1

   --if everyone has fought, create next population   
   if(current_indiv > popSize) then
      sort_pop()
      check_best()
      write_pop()   
      bestPop = trunc_selection(population)

      winner, loser = compete(population[1], bestIndiv)

      updateProbVec(winner, loser)
      generatePop()
      current_indiv = 1
      
   end
   start_new_game()
end

local function start()
   next_turn()
end

add_hook("enter_freeze","keep stepping",next_turn)
add_hook("end_game","start next game",next_game)
add_hook("new_game","start",start)