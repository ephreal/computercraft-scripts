-- Parses text input to LUNA and performs a redumentary sentiment analysis
-- Available moods are angry, chill, confused, frustrated, happy, scientific
-- smarmy, tired

function scriptPath()
   local str = debug.getinfo(2, "S").source:sub(2)
   return str:match("(.*/)") or "./"
end

local topicPath = fs.combine(scriptPath(), "knownTopics.lua")
print(topicPath)
local reader = fs.open(topicPath, "r")
local KNOWN_TOPICS = textutils.unserialise(reader.readAll())
reader.close()

-- Global variable to quickly tweak how the parser treats positivity/intensity
local MAX_POSITIVITY = 10
local MAX_INTENSITY = 10
local INTENSITY_INCREASE = 1
local INTENSITY_DECREASE = 0.5

-- Word lists to check for sentiment analysis
local negations = {"not", "never", "doesn't", "doesnt", "don't", "dont", "no", "isn't", "isnt"}
-- stopwords from https://ranks.nl/stopwords
-- Yes, some duplicates exist between this and negations, but negations are checked first.
local stopwords = {
        "a", "about", "above", "after", "again", "against",
        "all", "am", "an", "and", "any", "are", "aren't",
        "as", "at", "be", "because", "been", "before",
        "being", "below", "between", "both", "but", "by",
        "can't", "cannot", "could", "couldn't", "did",
        "didn't", "do", "does", "doesn't", "doing",
        "don't", "down", "during", "each", "few", "for",
        "from", "further", "had", "hadn't", "has", "hasn't",
        "have", "haven't", "having", "he", "he'd", "he'll",
        "he's", "her", "here", "here's", "hers", "herself",
        "him", "himself", "his", "how", "how's", "i", "i'd",
        "i'll", "i'm", "i've", "if", "in", "into", "is",
        "isn't", "it", "it's", "its", "itself", "let's",
        "me", "more", "most", "mustn't", "my", "myself",
        "no", "nor", "not", "of", "off", "on", "once",
        "only", "or", "other", "ought", "our", "ours",
        "ourselves", "out", "over", "own", "same",
        "shan't", "she", "she'd", "she'll", "she's",
        "should", "shouldn't", "so", "some", "such", "than",
        "that", "that's", "the", "their", "theirs", "them",
        "themselves", "then", "there", "there's", "these",
        "they", "they'd", "they'll", "they're", "they've",
        "this", "those", "through", "to", "too", "under",
        "until", "up", "very", "was", "wasn't", "we",
        "we'd", "we'll", "we're", "we've", "were",
        "weren't", "what", "what's", "when", "when's",
        "where", "where's", "which", "while", "who",
        "who's", "whom", "why", "why's", "with", "won't",
        "would", "wouldn't", "you", "you'd", "you'll",
        "you're", "you've", "your", "yours", "yourself",
        "yourselves"}
local intensifiers = {"really", "very", "extremely", "super"}
local strongIntensifiers = {"bastard", "damn", "fuck", "fucking", "hell", "shit"}
local dampeners = {"kinda", "sorta", "slightly", "bit"}
local positive = {"amazing", "awesome", "great", "like", "love", "thank", "thanks", "sorry", "apologize"}
local negative = {"annoying", "bad", "broken", "failure", "hate", "slow", "stupid", "ugly"}

local Parser = {}
Parser.__index = Parser

function Parser.new()
    local self = {}
    setmetatable(self, Parser)

    return self
end

function Parser:containsWord(wordList, word)
    for _,w in ipairs(wordList) do
        if word == w then
            return true
        end
    end
    return false
end

function Parser:contextualize(inputString)
    local input = inputString:lower()

    local contextTokens = {}

    -- I'm not great with LUAs pattern matching, so here's a reference for me
    -- %f[%w] - Will match a whole word.
    local patterns = {
        
    }
end


function Parser:getTopics(inputString)
    local input = inputString:lower()
    local topicScores = {}

    for topic,words in pairs(KNOWN_TOPICS) do
        topicScores[topic] = 0
        for _,word in pairs(words) do
            -- We want to match the whole word
            local pattern = "%f[%w]" .. word.word .. "%f[%W]"
            local _, count = input:gsub(pattern, "")
            topicScores[topic] = topicScores[topic] + (count * word.weight)
        end
    end
    return topicScores
end

function Parser:parse(inputString)
    local topics = self:getTopics(inputString)
    for topic,score in pairs(topics) do
        print(topic .. ": " .. score)
    end
    local positivity, intensity = self:parseSentiment(inputString)
    return topics, positivity, intensity
end

function Parser:parseSentiment(inputString)
    -- Make sure this is a case insensitive check
    inputString = inputString:lower()
    local positivity = 0
    local intensity = 0

    -- How intense the current word is deeemed
    local currentIntensity = 1
    -- Whether or not the last token is a negation
    local lastNeg = false

    local tokens = {}

    for word in inputString:gmatch("%w+") do
        table.insert(tokens, word)
    end

    -- Add a small amount of intensity if the string ends with an !
    if inputString:find("!$") then
        intensity = intensity + 0.5
    end

    -- Tweak the starting conditions to be "curious" if this is a question
    if inputString:find("?$") then
        intensity = 0.1
        positivity = 1
    end

    for i,word in ipairs(tokens) do
        if self:containsWord(negations, word) then
            lastNeg = false
        elseif self:containsWord(stopwords, word) then
            -- Do nothing, just move to the next word
        elseif self:containsWord(strongIntensifiers, word) then
            intensity = intensity + (INTENSITY_INCREASE * 2)
            positivity = positivity - (INTENSITY_INCREASE * 2)
        elseif self:containsWord(intensifiers, word) then
            currentIntensity = currentIntensity + INTENSITY_INCREASE
        elseif self:containsWord(dampeners, word) then
            currentIntensity = math.min(0.1, currentIntensity - INTENSITY_DECREASE)
        elseif self:containsWord(positive, word) then
            local score = 1
            if lastNeg then
                score = -1
            end

            intensity = intensity + currentIntensity

            positivity = positivity + (score * currentIntensity)
            lastNeg = false
            currentIntensity = 1
        elseif self:containsWord(negative, word) then
            local score = -1
            if lastNeg then
                score = 1
            end

            intensity = intensity + currentIntensity

            positivity = positivity + (score * currentIntensity)
            lastNeg = false
            currentIntensity = 1
        end
    end

    positivity = math.max(-MAX_POSITIVITY, math.min(MAX_POSITIVITY, positivity))
    intensity = math.max(0, math.min(MAX_INTENSITY, intensity))

    return positivity, intensity
end

return Parser
