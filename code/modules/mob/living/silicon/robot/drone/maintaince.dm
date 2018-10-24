/mob/living/silicon/robot/drone/maintaince

	// We need to keep track of a few module items so we don't need to do list operations
	// every time we need them. These get set in New() after the module is chosen.
	var/obj/item/stack/sheet/metal/cyborg/stack_metal = null
	var/obj/item/stack/sheet/wood/cyborg/stack_wood = null
	var/obj/item/stack/sheet/glass/cyborg/stack_glass = null
	var/obj/item/stack/sheet/mineral/plastic/cyborg/stack_plastic = null
	var/obj/item/weapon/matter_decompiler/decompiler = null


/mob/living/silicon/robot/drone/maintaince/atom_init()

	..()

	module = new /obj/item/weapon/robot_module/maintdrone(src)

	//Grab stacks.
	stack_metal = locate(/obj/item/stack/sheet/metal/cyborg) in src.module
	stack_wood = locate(/obj/item/stack/sheet/wood/cyborg) in src.module
	stack_glass = locate(/obj/item/stack/sheet/glass/cyborg) in src.module
	stack_plastic = locate(/obj/item/stack/sheet/mineral/plastic/cyborg) in src.module

	//Grab decompiler.
	decompiler = locate(/obj/item/weapon/matter_decompiler) in src.module

	//Some tidying-up.
	flavor_text = "It's a tiny little repair drone. The casing is stamped with an NT logo and the subscript: 'NanoTrasen Recursive Repair Systems: Fixing Tomorrow's Problem, Today!'"
	updateicon()

/mob/living/silicon/robot/drone/maintaince/init()
	laws = new /datum/ai_laws/drone()
	connected_ai = null

	..()

/mob/living/silicon/robot/drone/maintaince/updatename()
	real_name = "maintenance drone ([rand(100,999)])"
	name = real_name

//Drones can only use binary and say emotes. NOTHING else.
//TBD, fix up boilerplate. ~ Z
/mob/living/silicon/robot/drone/maintaince/say(var/message)

	if (!message)
		return

	if (src.client)
		if(client.prefs.muted & MUTE_IC)
			to_chat(src, "You cannot send IC messages (muted).")
			return
		if (src.client.handle_spam_prevention(message,MUTE_IC))
			return

	message = sanitize(message)

	if (stat == DEAD)
		return say_dead(message)

	if(copytext(message,1,2) == "*")
		return emote(copytext(message,2))
	else if(length(message) >= 2)

		if(parse_message_mode(message, "NONE") == "dronechat")

			if(!is_component_functioning("radio"))
				to_chat(src, "\red Your radio transmitter isn't functional.")
				return

			for (var/mob/living/S in living_mob_list)
				if(isdrone(S))
					to_chat(S, "<i><span class='game say'>Drone Talk, <span class='name'>[name]</span><span class='message'> transmits, \"[trim(copytext(message,3))]\"</span></span></i>")

			for (var/mob/M in dead_mob_list)
				if(!isnewplayer(M) && !isbrain(M))
					to_chat(M, "<i><span class='game say'>Drone Talk, <span class='name'>[name]</span><span class='message'> transmits, \"[trim(copytext(message,3))]\"</span></span></i>")

		else

			var/list/listeners = hearers(5,src)
			listeners |= src

			for(var/mob/living/silicon/robot/drone/D in listeners)
				if(D.client)
					to_chat(D, "<b>[src]</b> transmits, \"[message]\"")

			for(var/mob/M in player_list)
				if(isnewplayer(M))
					continue
				else if(M.stat == DEAD &&  M.client.prefs.chat_toggles & CHAT_GHOSTEARS)
					if(M.client)
						to_chat(M, "<b>[src]</b> transmits, \"[message]\"")

/mob/living/silicon/robot/drone/maintaince/full_law_reset()
	..()
	laws = new /datum/ai_laws/drone

/mob/living/silicon/robot/drone/maintaince/transfer_personality(client/player)
	..()
	to_chat(src, "<b>Systems rebooted</b>. Loading base pattern maintenance protocol... <b>loaded</b>.")
	to_chat(src, "<br><b>You are a maintenance drone, a tiny-brained robotic repair machine</b>.")
	to_chat(src, "You have no individual will, no personality, and no drives or urges other than your laws.")
	to_chat(src, "Use <b>:d</b> to talk to other drones and <b>say</b> to speak silently to your nearby fellows.")
	to_chat(src, "Remember,  you are <b>lawed against interference with the crew</b>. Also remember, <b>you DO NOT take orders from the AI.</b>")
	to_chat(src, "<b>Don't invade their worksites, don't steal their resources, don't tell them about the changeling in the toilets.</b>")
	to_chat(src, "<b>If a crewmember has noticed you, <i>you are probably breaking your third law</i></b>.")

/mob/living/silicon/robot/drone/maintaince/start_pulling(atom/movable/AM)

	if(istype(AM,/obj/item/pipe) || istype(AM,/obj/structure/disposalconstruct))
		..()
	..()