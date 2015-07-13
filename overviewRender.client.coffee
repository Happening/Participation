Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Form = require 'form'
Modal = require 'modal'
Obs = require 'obs'
Page = require 'page'
Plugin = require 'plugin'
Rnd = require 'rand'
Server = require 'server'
{tr} = require 'i18n'
Ui = require 'ui'

exports.render = ->
	chatIcon3 = [5,0,-3,"butt",-4,"miter",-5,4,4,2,0.03097373416806601,0.03097373416806601,2,2,0,0.0722720685046361,2,2,0,0,4,2,1.0666666577869877,1.0666666577869877,2,2,-470.71484,-465.13086,7,0,10,2,476.91797,465.13086,16,6,473.48159,465.13086,470.71484,467.89566,470.71484,471.33203,11,2,470.71484,479.99805,16,6,470.71484,483.43442,473.48159,486.20117,476.91797,486.20117,11,2,488.32031,486.20117,11,2,497.57227,491.02344,11,2,497.74414,485.45312,16,6,499.67593,484.40454,500.98242,482.35899,500.98242,479.99805,11,2,500.98242,471.33203,16,6,500.98242,467.89566,498.21567,465.13086,494.7793,465.13086,11,2,476.91797,465.13086,12,0,8,0,6,0]

	isMod = Plugin.userIsAdmin() || (Plugin.ownerId() is Plugin.userId())

	Dom.section !->
		if Event.clearIsNewCache then Event.clearIsNewCache() #workaround for: chearCache called after render, instead of before. Will be fixed in core in the future. Hopefully.
		if not Db.shared.get 'queries'
			Dom.h4 "No participations yet."
		else
			nrP = 0
			Db.shared.iterate 'queries', (query) !->
				#if hidden, skip (unless we're admin)
				if query.get('status') isnt 3 or isMod
					++nrP
					Dom.div !->
						Dom.style
							Flex: 1
							display: 'flex' # dunno why this isn't het with 'Flex: 1'
							Box: 'bottom'
						Dom.div !->
							status = query.get('status') #0 = open, 1 = closed, 2 = hidden

							Dom.style
								Flex: 1
								# position: 'relative'
								Box: 'center'
								paddingRight: '8px'
							
							#The title and subtitle
							Dom.div !->
								c = '#888'
								if status isnt 1 then c = '#aaa'
								if Event.isNew(query.get('time'), query.key()) then c = '#5b0'
								Dom.style
									padding: '20px 8px 10px 8px'
									Flex: 1
									color: c

								Dom.h3 !->
									Dom.style
										marginTop: '0px'
										color: c
									Dom.text query.get('title')

								# if status isnt 1 then Dom.last().style 'color': c
								Dom.text query.get('text')

							Dom.div !->
								Dom.style
									Box: 'vertical right bottom'
									margin: '10px 0px'
									# Flex: 1

								# if not admin, print 'closed' if the Participation is.
								if not isMod and status is 2
									Dom.span !->
										Dom.style
											color: '#aaa'
										Dom.text "Closed"

							#add the chat icon
								Dom.div !->
									Dom.style
										position: 'relative'
										# Box: 'middle'
										# marginTop: '5px'

									c = '#888'
									if status isnt 1 then c = '#aaa'
									if Event.isNew(query.get('updateTime'), query.key()) then c = '#5b0'

									require('icon').render(data: chatIcon3, color: c)
									# Dom.last().style 'margin-right': '5px'
									Dom.span !->
										Dom.style
											position: 'absolute'
											left: '5px'
											top: '1px'
											textAlign: 'center'
											width: '13px'
											fontSize: '12px'
											color: '#fff'
										Dom.text query.get('repliesId')

							Dom.onTap !-> Page.nav query.key() # argument adds /key() to the url

						#if admin, print status change options.
						if isMod
							Form.vSep()
							Dom.last().style
								"align-self": "stretch"
								"margin": "20px 0px 10px 0px"
								"min-height": "30px"

							Dom.div !->
								Dom.style
									Box: 'vertical bottom right'
									marginTop: '5px'
									padding: '10px 10px'

								Dom.div !->
									Dom.style
										Box: 'vertical'
										textAlign: 'right'
										fontWeight: 'bold'
										fontSize: '14px'
										textTransform: 'uppercase'
										color: "#bbb"

									mode = query.get('status')-1
									for x,n in [tr("Open"), tr("Closed"), tr("Hidden")]
										Dom.span !->
											Dom.text x
											if mode==n 
												Dom.style color: Plugin.colors().highlight

								Dom.onTap !->
									# modeO.set((modeO.peek()+1)%3)
									newStatus = ((query.peek('status'))%3)+1
									Server.sync 'status', query.key(), newStatus, !->
										#this function toggles the already temporarily. The server side does this for real.
										query.modify 'status', -> newStatus
				#seperator
					Dom.div !->
						Form.sep()
			if nrP is 0
				#No participations are added or visible.
				Dom.h4 "No participations yet..."

	#add 'add query'
		if isMod
			Dom.div !->
				Dom.style
					Flex: 1
					padding: '18px 8px'
					color: Plugin.colors().highlight

				Dom.text tr '+ Add participation'
				radio = []
				Dom.onTap !->
					Page.nav !->
						selection = null
						Dom.css
							".pressed":
								backgroundColor: "#f00 !important"
						Form.input
							name: 'title'
							text: 'Title'
						Form.input
							name: 'text'
							text: 'Optional description'

						Form.hidden "status", 1
						statusO = Dom.last()
						Dom.div !->
							Dom.style
								Box: 'left middle'
								padding: '10px'

							Dom.span "Initial status:"

							modeO = Obs.create 0
							Dom.div !->
								Dom.style
									Flex: 1
									Box: 'vertical'
									textAlign: 'right'
									fontWeight: 'bold'
									fontSize: '14px'
									textTransform: 'uppercase'
									color: "#bbb"
								
								mode = modeO.get()
								statusO.value( mode + 1 )
								for val,n in [tr("Open"), tr("Closed"), tr("Hidden")]
									Dom.span !->
										Dom.text val
										if mode == n 
											Dom.style color: Plugin.colors().highlight
								Dom.onTap !->
									modeO.set ((mode+1)%3)

						Form.setPageSubmit (d) !->
							if d.title
								Server.call 'new', d, !->
								Page.back()