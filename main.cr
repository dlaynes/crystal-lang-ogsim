require "json"
require "file"

require "./src/odb/resource.cr"
require "./src/odb/fleet.cr"
require "./src/odb/utils.cr"

timer = Profiler.new
timer.startTask "full_simulation"

resources = Hash(String, Resource).from_json(File.read("./config/resources.json"))
rapidfires = Hash(String, Hash(String, Int32)).from_json(File.read("./config/rapidfire.json"))

resources.each do |id, res|
  if rapidfires[id]?
    res.processRapidfire rapidfires[id]
  end
end

attackers = Array(Fleet).from_json(File.read("./data/attackers.json"))
defenders = Array(Fleet).from_json(File.read("./data/defenders.json"))

attGroup = FleetGroup.new
attGroup.setResources resources
defGroup = FleetGroup.new
defGroup.setResources resources

timer.startTask "init_attackers"
attackers.each do |attacker|
  attGroup.expandFleet attacker
end
timer.endTask "init_attackers"

timer.startTask "init_defenders"
defenders.each do |defender|
  defGroup.expandFleet defender
end
timer.endTask "init_defenders"

# puts defGroup.@ships

turns = 6
exitBattle = false

timer.startTask "full_battle"

attGroup.calcStatistics 0
defGroup.calcStatistics 0

(1..turns).each do |turn|
  if attGroup.@ships.size < 1
    puts "Attacker group has no remaining ships in battle"
    exitBattle = true
  end

  if defGroup.@ships.size < 1
    puts "Defender group has no remaining ships in battle"
    exitBattle = true
  end

  if exitBattle
    break
  end

  timer.startTask "round_" + turn.to_s

  timer.startTask "round_attackers_" + turn.to_s
  attGroup.attack defGroup
  timer.endTask "round_attackers_" + turn.to_s
  timer.startTask "round_defenders_" + turn.to_s
  defGroup.attack attGroup
  timer.endTask "round_defenders_" + turn.to_s

  timer.startTask "clean_attackers_" + turn.to_s
  attGroup.updateShips
  timer.endTask "clean_attackers_" + turn.to_s
  timer.startTask "clean_defenders_" + turn.to_s
  defGroup.updateShips
  timer.endTask "clean_defenders_" + turn.to_s

  attGroup.calcStatistics turn
  defGroup.calcStatistics turn

  timer.endTask "round_" + turn.to_s
end

timer.endTask "full_battle"

timer.endTask "full_simulation"

tasks = timer.getTasks

# puts tasks

tasks.each do |task|
  task = task.as(Task)
  puts "Task " + task.@label + " took " + task.elapsedTime.to_s + "ms\n"
end

puts "Ok..."
