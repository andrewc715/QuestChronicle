QuestChronicle={Wardrobe={_Private={}}}
local Wardrobe,P=QuestChronicle.Wardrobe,QuestChronicle.Wardrobe._Private
local builds=0
Wardrobe.GetWeaponAppearanceCapabilities=function()
    builds=builds+1
    return { topology={mainItem=100,offItem=200}, routes={}, availableFamilies={} }
end
local root=debug.getinfo(1,"S").source:sub(2):gsub("tools/test_weapon_capability_snapshot_v1115.lua$","")
assert(loadfile(root.."Core/Wardrobe/WeaponCapabilitySnapshot.lua"))()
local job={}
local first,status1,generation1=P.GetWeaponCapabilitySnapshotForJob(job)
local second,status2,generation2=P.GetWeaponCapabilitySnapshotForJob(job)
assert(first==second and builds==1,"action capability snapshot was rebuilt")
assert(status1=="BUILT" and status2=="REUSED" and generation1==generation2,"action snapshot status changed")
assert(job.weaponCapabilityBuildsThisAction==1 and job.weaponCapabilityReusesThisAction==1,"action counters changed")
local valid=P.ValidateWeaponCapabilitySnapshotAtCommit(job)
assert(valid and job.weaponCapabilityStaleAtCommit==false,"fresh capability snapshot was rejected")
P.InvalidateWeaponCapabilitySnapshot("CHARACTER_CAPABILITY_CHANGED")
local valid2,reason=P.ValidateWeaponCapabilitySnapshotAtCommit(job)
assert(not valid2 and job.weaponCapabilityStaleAtCommit==true and reason:find("Weapon equipment",1,true),"stale action was not cancelled")
local nextJob={}
local third,status3,generation3=P.GetWeaponCapabilitySnapshotForJob(nextJob)
assert(third~=nil and status3=="BUILT" and builds==2,"invalidated session snapshot was not rebuilt")
assert(generation3==generation1+1 and nextJob.weaponCapabilityInvalidationReason=="CHARACTER_CAPABILITY_CHANGED","capability generation lineage changed")
print("PASS v1.11.5 weapon capability snapshot: one build per action and explicit invalidation cancels stale commit")
