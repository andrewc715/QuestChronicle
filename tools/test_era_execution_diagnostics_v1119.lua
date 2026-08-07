QuestChronicle={Wardrobe={_Private={}},ZoneStyle={_Private={eraSynchronousProgressGuardTrips=4}},Diagnostics={_Private={}}}
local P=QuestChronicle.Wardrobe._Private
function P.BuildWeaponIndexActionDiagnostics() return nil end
function P.BuildGenerationCachePerformance() return nil end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Wardrobe/GenerationPerformance.lua")
local job={startedAtMs=0,steps=4,maxStepMs=4.2,phaseStats={},eraSynchronousProgressGuardStart=3,
 eraOperations=8,eraSiblingCompletions=2,eraFreshSliceDeferrals=3,eraDeferredReturns=3,eraSameSliceDeferredRetries=0,
 eraFragmentCacheHits=1,eraFragmentCacheBuilds=1,eraAggregateFinalizations=1}
local perf=P.BuildGenerationPerformance(job,20)
local era=perf.eraScheduling
assert(era.executionMode=="GENERATION_COOPERATIVE","execution mode missing")
assert(era.deferredReturns==3 and era.sameSliceDeferredRetries==0,"deferred counters changed")
assert(era.synchronousProgressGuardTrips==1,"synchronous guard delta changed")
dofile(base.."Core/Diagnostics/EraPerformanceFormatter.lua")
local lines={}; QuestChronicle.Diagnostics._Private.AddEraSchedulingPerformanceLines(lines,perf,{})
local joined=table.concat(lines,"\n")
assert(joined:find("Era execution boundary:",1,true),"formatter omitted execution boundary")
assert(joined:find("same-slice retries",1,true),"formatter omitted retry counter")
assert(joined:find("synchronous guard trips",1,true),"formatter omitted guard counter")
print("PASS v1.11.9 era execution-boundary diagnostics retain watchdog counters")
