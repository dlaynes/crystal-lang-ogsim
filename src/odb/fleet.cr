class Planet
  JSON.mapping({
    galaxy:     Int32,
    system:     Int32,
    position:   Int32,
    planetType: Int32,
  })
end

class Fleet
  JSON.mapping({
    id:            Int32,
    name:          String,
    mainPlanet:    Planet,
    originalFleet: Hash(String, Int32),
    militaryTech:  Int32,
    defenseTech:   Int32,
    hullTech:      Int32,
  })

  @shipTypes : Hash(Int32, ShipType) = {} of Int32 => ShipType

  def expandTo(
               resourceList : Hash(String, Resource),
               fleetList : Array({Float64, Float64, ShipType}))
    originalFleet.each do |id, amount|
      resource_id = id.to_i
      shipType = ShipType.new(resourceList[id], @defenseTech.to_f, @militaryTech.to_f, @hullTech.to_f, amount)

      h = shipType.@baseHull
      d = shipType.@baseShield

      amount.times do |i|
        fleetList << {h, d, shipType}
      end

      @shipTypes[resource_id] = shipType
    end
  end
end

class ShipType
  @baseShield : Float64 = 0.0
  @baseAttack : Float64 = 0.0
  @baseHull : Float64 = 0.0
  @rapidfires : Hash(Int32, Float64) = {} of Int32 => Float64
  @id : Int32 = 0

  def initialize(
                 res : Resource,
                 defenseTech : Float64,
                 militaryTech : Float64,
                 hullTech : Float64,
                 @amount : Int32 = 0,
                 @explosions : Int32 = 0,
                 @statistics : Array(Int32) = [] of Int32)
    d = 1 + (militaryTech * 0.1)
    s = 1 + (defenseTech * 0.1)
    h = (1 + (hullTech * 0.1)) * 0.1

    @id = res.id
    @baseAttack = d * res.attack
    @baseShield = s * res.defense
    @baseHull = h * res.hull
    @rapidfires = res.@rapidfires
  end

  def explosions=(@explosions)
  end
end

class FleetGroup
  @resourceList : Hash(String, Resource) = {} of String => Resource

  def initialize(
                 @turnDamage : Float64 = 0.0,
                 @turnDefense : Float64 = 0.0,
                 @turnAttacks : Int32 = 0,
                 @ships : Array({Float64, Float64, ShipType}) = [] of Tuple(Float64, Float64, ShipType))
  end

  def setResources(resources : Hash(String, Resource))
    @resourceList = resources
  end

  def expandFleet(fleet : Fleet)
    fleet.expandTo(@resourceList, @ships)
  end

  def calcStatistics(turn : Int32)
    if turn > 0
      puts "The fleet attacked " + @turnAttacks.to_s + " times with " + @turnDamage.to_s + " hit points"
      puts "The contrary fleet shields absorbed " + @turnDefense.to_s + " points of damage"
    end

    @turnDamage = 0.0
    @turnDefense = 0.0
  end

  def updateShips
    puts "Length before cleanup " + @ships.size.to_s

    newShips = Array({Float64, Float64, ShipType}).new(@ships.size)

    @ships.each do |ship|
      if ship[0] != 0.0
        newShips << {ship[0], ship[2].@baseShield, ship[2]}
      end
    end
    @ships = newShips
    puts "Length after cleanup " + @ships.size.to_s
  end

  def setShips(ships)
    @ships = ships
  end

  def attack(group : FleetGroup)
    Random.new_seed
    enemy_count = group.@ships.size
    tA = @ships.size
    tDm = 0.0
    tDf = 0.0
    enemyShips = group.@ships

    rn = Random.new

    # puts "attacking"
    # puts @ships

    # puts "defending"
    # puts enemyShips

    @ships.each do |ship|
      dm = ship[2].@baseAttack
      unitType = ship[2]
      running = true

      # puts dm

      while running
        enemyPos = Random.rand(enemy_count)
        enemyShip = enemyShips[enemyPos]
        tDm += dm

        enemyShipType = enemyShip[2]

        if enemyShip[0] != 0.0
          if dm * 100 > enemyShipType.@baseShield
            if dm > enemyShip[1]
              de = dm - enemyShip[1]
              tDf += enemyShip[1]

              if de < enemyShip[0]
                remaining = enemyShip[0] - de
                xp = (enemyShipType.@baseHull - remaining) / remaining
                if xp > 0.3 && rn.next_float < xp
                  # boom!
                  enemyShipType.explosions = enemyShipType.@explosions + 1 # .....
                  enemyShips[enemyPos] = {0.0, 0.0, enemyShipType}
                else
                  # puts remaining
                  enemyShips[enemyPos] = {remaining, 0.0, enemyShipType}
                end
              else
                # boom!
                enemyShips[enemyPos] = {0.0, 0.0, enemyShipType}
              end
            else
              tDf += dm
              enemyShips[enemyPos] = {enemyShip[0], enemyShip[1] - dm, enemyShipType}
            end
          else
            tDf += dm
            running = false
          end
        end

        eid = enemyShipType.@id
        if unitType.@rapidfires[eid]? && unitType.@rapidfires[eid] > rn.next_float
          tA += 1
          running = true
        else
          running = false
        end
      end
    end

    group.setShips(enemyShips)
    @turnAttacks = tA
    @turnDefense = tDf
    @turnDamage = tDm
  end
end
