Page = require 'page'
ParticipationRender = require 'participationRender'
OverviewRender = require 'overviewRender'

# Initial entree point
exports.render = !->
	if storyId = 0|Page.state.get(0) #read /1 from the url
		return ParticipationRender.render storyId
	
	#If we're not in a participation, we render the overview
	return OverviewRender.render()
