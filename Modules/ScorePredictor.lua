--[[
    MythicPulse - Score Predictor Module
    Estimates Mythic+ rating gain from a run.

    NOTE on accuracy:
      Blizzard's exact scoring formula varies per season and is not officially
      published. We use a conservative linear approximation that matches
      published community values within a few points. This is meant as a
      DECISION-MAKING tool ("is this worth pushing?"), not an exact predictor.

    Formula approximation (TWW Season 3 / Midnight Season 1 baseline):
      base   = 155 + 15 * (level - 2)         -- score for a timed run
      bonus  = +7.5 per chest tier above +1   (timed = +1, +2 chest = +7.5, +3 = +15)
      depleted = base * 0.5                   -- rough penalty for an over-time finish
      final = max(base or depleted) - existingScoreForThatMap

    The dungeon contributes the BEST of its Tyrannical/Fortified halves, so
    the actual rating gain is half of (newScore - oldScore) plus weekly best
    weighting. We surface "raw run score" and "delta vs existing best" — the
    user gets actionable info either way.
]]

local _, MP = ...

local ScorePredictor = {}

----------------------------------------------------------------------
-- Estimate a run's raw score given (level, timed-status, chestTier)
-- chestTier: 1 (in time), 2 (+2 chest), 3 (+3 chest); ignored if not timed
----------------------------------------------------------------------
function ScorePredictor:EstimateRunScore(level, timed, chestTier)
    if not level or level < 2 then return 0 end
    local base = 155 + 15 * (level - 2)
    if not timed then
        return math.floor(base * 0.5)
    end
    local bonus = 0
    if chestTier and chestTier > 1 then
        bonus = (chestTier - 1) * 7.5
    end
    return math.floor(base + bonus)
end

----------------------------------------------------------------------
-- Determine the chest tier from elapsed and timeLimit.
-- 1 = timed (under timeLimit)
-- 2 = +2 chest (under 80% of timeLimit)
-- 3 = +3 chest (under 60% of timeLimit)
-- 0 = depleted (over timeLimit)
----------------------------------------------------------------------
function ScorePredictor:GetChestTier(elapsed, timeLimit)
    if not elapsed or not timeLimit or timeLimit <= 0 then return 0 end
    if elapsed > timeLimit then return 0 end
    local ratio = elapsed / timeLimit
    if ratio < 0.60 then return 3 end
    if ratio < 0.80 then return 2 end
    return 1
end

----------------------------------------------------------------------
-- Get the player's current best score for a specific dungeon.
-- Returns nil if API is unavailable or no run is recorded.
----------------------------------------------------------------------
function ScorePredictor:GetExistingBestForMap(mapID)
    if not mapID or not C_MythicPlus then return nil end
    if C_MythicPlus.GetSeasonBestForMap then
        local result = C_MythicPlus.GetSeasonBestForMap(mapID)
        if type(result) == "table" then
            -- Modern API: returns a table with score
            return result.dungeonScore or result.score or nil
        end
    end
    return nil
end

----------------------------------------------------------------------
-- Predict score delta for a run.
-- Returns: { runScore, existingBest, delta, chestTier }
----------------------------------------------------------------------
function ScorePredictor:PredictRun(runData)
    if not runData then return nil end
    local mapID    = runData.mapID
    local level    = runData.keyLevel or 0
    local elapsed  = runData.elapsed or 0
    local limit    = runData.timeLimit or 0
    local timed    = runData.timed and true or false

    local chestTier = self:GetChestTier(elapsed, limit)
    local runScore  = self:EstimateRunScore(level, timed, chestTier)
    local existing  = self:GetExistingBestForMap(mapID)
    local delta     = nil
    if existing then
        delta = math.max(0, runScore - existing)
    end

    return {
        runScore    = runScore,
        existingBest= existing,
        delta       = delta,
        chestTier   = chestTier,
        timed       = timed,
    }
end

----------------------------------------------------------------------
-- Register
----------------------------------------------------------------------
MP.ScorePredictor = ScorePredictor
ScorePredictor.registeredEvents = {}
MP:RegisterModule("ScorePredictor", ScorePredictor)
