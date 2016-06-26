class Resource
  JSON.mapping({
    id:           Int32,
    name:         String,
    metal:        {type: Int32, default: 0},
    crystal:      {type: Int32, default: 0},
    deuterium:    {type: Int32, default: 0},
    energy:       {type: Int32, default: 0},
    factor:       {type: Float64, default: 0.0},
    speed:        {type: Int32, default: 0},
    capacity:     {type: Int32, default: 0},
    attack:       {type: Float64, default: 0.0},
    defense:      {type: Float64, default: 0.0},
    hull:         {type: Float64, default: 0.0},
    motors:       {type: Hash(String, Int32), default: {} of String => Int32},
    speeds:       {type: Hash(String, Int32), default: {} of String => Int32},
    consumptions: {type: Hash(String, Int32), default: {} of String => Int32},
  })

  @rapidfires : Hash(Int32, Float64) = {} of Int32 => Float64

  def processRapidfire(rfRaw : Hash(String, Int32))
    rfRaw.each do |k, value|
      @rapidfires[k.to_i] = (1.0 - (1.0 / value.to_f))
    end
  end
end
