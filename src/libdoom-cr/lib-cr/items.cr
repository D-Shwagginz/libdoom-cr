# Weapon info: sprite frames, ammunition use.
struct Weaponinfo
  property ammo : Ammotype = Ammotype.new(0)
  property upstate : Int32 = 0
  property downstate : Int32 = 0
  property readystate : Int32 = 0
  property atkstate : Int32 = 0
  property flashstate : Int32 = 0
end

weaponinfo : Array(Weaponinfo) = Array(Weaponinfo).new(NUMWEAPONS, Weaponinfo.new)
