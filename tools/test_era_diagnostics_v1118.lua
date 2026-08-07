local function JsonString(value)
 value=tostring(value or ""):gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r"):gsub("\t","\\t")
 return '"'..value..'"'
end
local function IsArray(t)
 local n,max=0,0; for k in pairs(t) do if type(k)~="number" or k<1 or k%1~=0 then return false end; n=n+1; max=math.max(max,k) end; return max==n
end
local function Encode(v,seen)
 local ty=type(v); if v==nil then return "null" elseif ty=="boolean" then return v and "true" or "false" elseif ty=="number" then return tostring(v) elseif ty=="string" then return JsonString(v) elseif ty~="table" then return JsonString(tostring(v)) end
 seen=seen or {}; if seen[v] then return "null" end; seen[v]=true; local parts={}
 if IsArray(v) then for i=1,#v do parts[#parts+1]=Encode(v[i],seen) end else local keys={}; for k in pairs(v) do keys[#keys+1]=k end; table.sort(keys,function(a,b)return tostring(a)<tostring(b)end); for _,k in ipairs(keys) do parts[#parts+1]=JsonString(k)..":"..Encode(v[k],seen) end end
 seen[v]=nil; return (IsArray(v) and "[" or "{")..table.concat(parts,",")..(IsArray(v) and "]" or "}")
end
QuestChronicle={_Core={JsonEncode=Encode},Diagnostics=nil,Wardrobe={_Private={GENERATION_PHASE_LABELS={eraSetList="Era set-list acquisition"}}}}
QuestChronicleDB={ui={}}
QuestChronicle.GetCurrentCharacter=function() return {key="T-R",name="T",realm="R"} end
QuestChronicle.Print=function() end; QuestChronicle.Notify=function() end
local root=(... and (...):match("^(.*)[/\\]") or ""); local base=root~="" and root.."/../" or ""
dofile(base.."Core/Diagnostics/Foundation.lua")
dofile(base.."Core/Diagnostics/ReportEmergencyStub.lua")
dofile(base.."Core/Diagnostics/ReportCompaction.lua")
dofile(base.."Core/Diagnostics/History.lua")
dofile(base.."Core/Diagnostics/EraPerformanceFormatter.lua")
local D,P=QuestChronicle.Diagnostics,QuestChronicle.Diagnostics._Private
local era={operations=444,siblingCompletions=37,freshSliceDeferrals=19,deferredReturns=19,sameSliceDeferredRetries=0,synchronousProgressGuardTrips=0,executionMode="GENERATION_COOPERATIVE",fragmentCacheHits=22,fragmentCacheBuilds=15,
 pendingCandidateCompletions=2,setListCalls=15,setEntryCalls=28,trackingCalls=15,encounterListCalls=15,
 encounterEntryOperations=61,itemMetadataCalls=4,aggregateFinalizations=37,largestSubphase="eraSetList",largestSubphaseMs=2.75}
local huge=string.rep("diagnostic-detail-",900)
local report,msg=D.AddReport({
 formatVersion=D.FORMAT_VERSION,id="QCDBG-ERA-1",sequence=1,timestamp=1,timestampText="2026-08-06",version="1.11.9",
 action="REROLL_UNLOCKED",mode="ZONE_NATIVE",generationImplementation="LEGACY",result="COMPLETED",success=true,
 character={key="T-R",name="T",realm="R"},message="Era scheduling fixture",
 zoneFoundation={foundation="CONTEXT_EVIDENCE_V1",fingerprint="ZCTX",anchorPolicy={policyID="ZONE_ANCHOR_POLICY_V1",authority="ACTIVE",selected={{slotKey="CHEST",name="Chest",legacyRelevance=10,zoneAdjustment=2,finalRelevance=12}}}},
 skeleton={components={{slotKey="CHEST",name="Chest",sourceID=1,visualID=2}},cohesionComponents={raw=huge}},
 support={finalValidationStatus="CLEAN",phaseDFinal={status="CLEAN"},profile={descriptor={raw=huge}}},
 performance={longestWorkerSliceMs=6.2,largestInstrumentedCallPhase="eraSetList",largestInstrumentedCallMs=2.75,
   schedulerDiagnostics={maximumSliceDebtMs=0.4,postExpensiveCallContinuations=0},eraScheduling=era,
   phaseStats={eraSetList={calls=15,maxMs=2.75,totalMs=20,raw=huge},eraSetEntry={calls=28,maxMs=.8,totalMs=9,raw=huge}},
   cacheDiagnostics={raw=huge}},
 beam={raw=huge},cache={raw=huge},warnings={},
})
assert(report,msg or "era diagnostic report rejected")
assert(report.approximateBytes<=D.MAX_REPORT_BYTES,"era report exceeded persistence ceiling")
assert(report.compaction and report.compaction.tier>=3,"fixture did not exercise summary-or-deeper compaction")
assert(report.performance and report.performance.eraScheduling,"era headline diagnostics lost during compaction")
local saved=report.performance.eraScheduling
for _,key in ipairs({"operations","siblingCompletions","freshSliceDeferrals","deferredReturns","sameSliceDeferredRetries","synchronousProgressGuardTrips","executionMode","fragmentCacheHits","largestSubphase","largestSubphaseMs"}) do
 assert(saved[key]==era[key],"era headline field lost: "..key)
end
assert(report.performance.schedulerDiagnostics.postExpensiveCallContinuations==0,"scheduler integrity lost")
assert(report.zoneFoundation.anchorPolicy.policyID=="ZONE_ANCHOR_POLICY_V1","Zone policy identity lost")

local lines={}; P.AddEraSchedulingPerformanceLines(lines,{eraScheduling=era},QuestChronicle.Wardrobe._Private.GENERATION_PHASE_LABELS)
local text=table.concat(lines,"\n")
for _,expected in ipairs({"Era evidence scheduling: 444 operations","37 siblings","19 fresh-slice deferrals","22 fragment hits","Era execution boundary: GENERATION_COOPERATIVE","0 same-slice retries","0 synchronous guard trips","Largest era subphase: Era set-list acquisition 2.75 ms"}) do
 assert(text:find(expected,1,true),"formatter missing: "..expected)
end
local empty={}; P.AddEraSchedulingPerformanceLines(empty,{},{}); assert(#empty==0,"historical report invented zero era diagnostics")

local emergency=D.AddReport({formatVersion=D.FORMAT_VERSION,id="QCDBG-ERA-2",sequence=2,timestamp=2,version="1.11.9",action="GENERATE_OUTFIT",mode="ZONE_NATIVE",result="COMPLETED",success=true,
 character={key="T-R"},message=string.rep("pathological ",25000),warnings={{key="X",severity="WARNING",text=string.rep("warn ",20000)}},
 performance={eraScheduling=era,schedulerDiagnostics={maximumSliceDebtMs=1,postExpensiveCallContinuations=0}},
 zoneFoundation={foundation="CONTEXT_EVIDENCE_V1",anchorPolicy={policyID="ZONE_ANCHOR_POLICY_V1",authority="ACTIVE",selected={}}},support={finalValidationStatus="CLEAN"},skeleton={components={}}})
assert(emergency,"emergency era report was rejected")
assert(emergency.performance and emergency.performance.eraScheduling,"emergency stub lost era scheduling")
assert(emergency.performance.eraScheduling.largestSubphase=="eraSetList","emergency stub lost largest era subphase")
print(string.format("PASS v1.11.9 era diagnostics survive adaptive tier %s and emergency persistence",tostring(report.compaction.tierLabel)))
