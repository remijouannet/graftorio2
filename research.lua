function on_research_finished(event)
        local research = event.research
        if not global.last_research then
                global.last_research = {}
        end
        
        local level = research.level
        -- Previous research is incorrect lvl if it has more than one research
        if level > 1 then
                level = level - 1
        end
        
        global.last_research[research.force.name] = {
                researched = 1,
                name = research.name,
                level = level
        }
end
