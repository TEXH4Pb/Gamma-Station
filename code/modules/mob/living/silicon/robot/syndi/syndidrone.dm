/mob/living/silicon/robot/syndidrone
	icon_state = "repairbot"
	lawupdate = 0
	scrambledcodes = 1
	faction = "syndicate"
	braintype = "Robot"
	pass_flags = PASSTABLE
	ventcrawler = 2
	maxHealth = 30
	health = 30
	req_access = list(access_syndicate)
	var/mob/living/master = null

	var/mail_destination = ""
	holder_type = /obj/item/weapon/holder/syndidrone

/mob/living/silicon/robot/syndidrone/atom_init()
	. = ..()

	cell.maxcharge = 10000
	cell.charge = 10000

	mmi = null

	radio = new /obj/item/device/radio/borg/syndicate(src)
	module = new /obj/item/weapon/robot_module/syndidrone(src)
	//set_zeroth_law("Only [master.real_name] and people he designates as being such are Syndicate Agents.")
	laws = new /datum/ai_laws/syndicate_override()

	//We need to screw with their HP a bit.
	for(var/V in components) if(V != "power cell")
		var/datum/robot_component/C = components[V]
		C.max_damage = 20

	flavor_text = "It's a tiny little repair drone. The casing is stamped with a red S logo and the subscript: 'Cybersun Industries: Fixing Today's Problem, Tomorrow!'"
	updateicon()

/mob/living/silicon/robot/syndidrone/init()

	aiCamera = new/obj/item/device/camera/siliconcam/drone_camera(src)
	playsound(src.loc, 'sound/machines/twobeep.ogg', 50, 0)

/mob/living/silicon/robot/syndidrone/updatename()
	var/T = rand(100,999)
	real_name = "syndicate drone ([T])"
	name = "maintenance drone ([T])"

/mob/living/silicon/robot/syndidrone/updateicon()
	overlays.Cut()
	if(stat == CONSCIOUS)
		overlays += "eyes-[icon_state]"
	else
		overlays -= "eyes"

/mob/living/silicon/robot/drone/choose_icon()
	return

/mob/living/silicon/robot/drone/pick_module()
	return

/mob/living/silicon/robot/drone/attackby(obj/item/weapon/W, mob/user)

	if(istype(W, /obj/item/borg/upgrade/))
		to_chat(user, "\red The maintenance drone chassis not compatible with \the [W].")
		return

	else if (istype(W, /obj/item/weapon/crowbar))
		to_chat(user, "The machine is hermetically sealed. You can't open the case.")
		return

	else if (istype(W, /obj/item/weapon/card/emag))

		if(!client || stat == DEAD)
			to_chat(user, "\red There's not much point subverting this heap of junk.")
			return

		to_chat(src, "\red [user] attempts to load subversive software into you, but your hacked subroutined ignore the attempt.")
		to_chat(user, "\red You attempt to subvert [src], but the sequencer has no effect.")
		return

	else if (istype(W, /obj/item/weapon/card/id)||istype(W, /obj/item/device/pda))

		if(stat == DEAD)

			if(health < -35)
				to_chat(user, "\red The interface is fried, and a distressing burned smell wafts from the robot's interior. You're not rebooting this one.")
				return

			if(!allowed(usr))
				to_chat(user, "\red Access denied.")
				return

			user.visible_message("\red \the [user] swipes \his ID card through \the [src], attempting to reboot it.", "\red You swipe your ID card through \the [src], attempting to reboot it.")
			var/drones = 0
			for(var/mob/living/silicon/robot/drone/D in mob_list)
				if(D.key && D.client)
					drones++
			if(drones < config.max_maint_drones)
				request_player()
			return

		else
			user.visible_message("\red \the [user] swipes \his ID card through \the [src], attempting to shut it down.", "\red You swipe your ID card through \the [src], attempting to shut it down.")

			if(allowed(usr))
				shut_down()
			else
				to_chat(user, "\red Access denied.")

		return

	..()

/mob/living/silicon/robot/syndidrone/updatehealth()
	if(status_flags & GODMODE)
		health = maxHealth
		stat = CONSCIOUS
		return
	health = maxHealth - (getBruteLoss() + getFireLoss())
	return

/mob/living/silicon/robot/syndidrone/handle_regular_status_updates()

	if(health <= -10 && src.stat != DEAD)
		timeofdeath = world.time
		death() //Possibly redundant, having trouble making death() cooperate.
		gib()
		return
	..()

/mob/living/silicon/robot/syndidrone/death(gibbed)

	if(module)
		var/obj/item/weapon/gripper/G = locate(/obj/item/weapon/gripper) in module
		if(G) G.drop_item()

	..(gibbed)

/mob/living/silicon/robot/syndidrone/proc/law_resync()
	if(stat != DEAD)
		to_chat(src, "\red A reset-to-factory directive packet filters through your data connection, and you obediently modify your programming to suit it.")
		full_law_reset()
		show_laws()

/mob/living/silicon/robot/syndidrone/proc/shut_down()
	if(stat != DEAD)
		to_chat(src, "\red You feel a system kill order percolate through your tiny brain, and you obediently destroy yourself.")
		death()

/mob/living/silicon/robot/syndidrone/proc/full_law_reset()
	clear_supplied_laws()
	clear_inherent_laws()
	clear_ion_laws()
	if(master)
		set_zeroth_law("Only [master.real_name] and people he designates as being such are Syndicate Agents.")
	laws = new /datum/ai_laws/syndicate_override()

/mob/living/silicon/robot/syndidrone/proc/request_player()
	for(var/mob/dead/observer/O in player_list)
		if(jobban_isbanned(O, ROLE_DRONE))
			continue
		if(role_available_in_minutes(O, ROLE_DRONE))
			continue
		if(O.client)
			var/client/C = O.client
			if(!C.prefs.ignore_question.Find("syndidrone") && (ROLE_PAI in C.prefs.be_role))
				question(C)

/mob/living/silicon/robot/syndidrone/proc/question(client/C)
	spawn(0)
		if(!C || !C.mob || jobban_isbanned(C.mob, ROLE_DRONE) || role_available_in_minutes(C.mob, ROLE_DRONE))//Not sure if we need jobban check, since proc from above do that too.
			return
		var/response = alert(C, "Someone is attempting to order a Syndicate drone. Would you like to play as one?", "Syndicate drone order", "No", "Yes", "Never for this round.")
		if(!C || ckey)
			return
		if(response == "Yes")
			transfer_personality(C)
		else if (response == "Never for this round")
			C.prefs.ignore_question += "syndidrone"

/mob/living/silicon/robot/syndidrone/proc/transfer_personality(client/player)

	if(!player) return

	src.ckey = player.ckey

	if(player.mob && player.mob.mind)
		player.mob.mind.transfer_to(src)

	lawupdate = 0
	to_chat(src, "<b>Systems rebooted</b>. Loading base pattern maintenance protocol... <b>loaded</b>.")
	full_law_reset()
	to_chat(src, "<br><b>You are a Syndicate drone, a tiny-brained robotic machine</b>.")
	to_chat(src, "You have no individual will, no personality, and no drives or urges other than your laws.")
	to_chat(src, "Use <b>;</b> to talk to Syndicate agents.")

/mob/living/silicon/robot/syndidrone/ObjBump(obj/O)
	var/list/can_bump = list(/obj/machinery/door,
							/obj/machinery/recharge_station,
							/obj/machinery/disposal/deliveryChute,
							/obj/machinery/teleport/hub,
							/obj/effect/portal)
	if(!(O in can_bump))
		return 0

/mob/living/silicon/robot/syndidrone/start_pulling(atom/movable/AM)
	if(istype(AM,/obj/item))
		var/obj/item/O = AM
		if(O.w_class > 2)
			to_chat(src, "<span class='warning'>You are too small to pull that.</span>")
			return
		else
			..()
	else
		to_chat(src, "<span class='warning'>You are too small to pull that.</span>")
		return

/mob/living/simple_animal/syndidrone/mob_negates_gravity()
	return 1

/mob/living/simple_animal/syndidrone/mob_has_gravity()
	return ..() || mob_negates_gravity()

/mob/living/silicon/robot/syndidrone/proc/set_master(mob/living/M)
	if(!M)
		return
	master = M
	set_zeroth_law("Only [master.real_name] and people he designates as being such are Syndicate Agents.")

// DRONE ABILITIES
/mob/living/silicon/robot/syndidrone/verb/set_mail_tag()
	set name = "Set Mail Tag"
	set desc = "Tag yourself for delivery through the disposals system."
	set category = "Drone"

	var/new_tag = input("Select the desired destination.", "Set Mail Tag", null) as null|anything in tagger_locations

	if(!new_tag)
		mail_destination = ""
		return

	to_chat(src, "\blue You configure your internal beacon, tagging yourself for delivery to '[new_tag]'.")
	mail_destination = new_tag

	//Auto flush if we use this verb inside a disposal chute.
	var/obj/machinery/disposal/D = src.loc
	if(istype(D))
		to_chat(src, "\blue \The [D] acknowledges your signal.")
		D.flush_count = D.flush_every_ticks

	return

/mob/living/silicon/robot/syndidrone/verb/hide()
	set name = "Hide"
	set desc = "Allows you to hide beneath tables or certain items. Toggled on or off."
	set category = "Drone"

	if (layer != TURF_LAYER+0.2)
		layer = TURF_LAYER+0.2
		to_chat(src, text("\blue You are now hiding."))
	else
		layer = MOB_LAYER
		to_chat(src, text("\blue You have stopped hiding."))

//Actual picking-up event.
/mob/living/silicon/robot/syndidrone/attack_hand(mob/living/carbon/human/M)

	if(M.a_intent == "help")
		get_scooped(M)
	..()

//Universal drone gripper
//TODO: replace it to drone_items.dm (or even refactor it... tomorrow)
/obj/item/weapon/gripper/universal

	can_hold = null //List of items which this object can grap (if set, it can't store anything else)
	var/list/cant_hold = null //List of items which this object can't grap (in effect only if can_hold isn't set)
	var/max_item_size = ITEM_SIZE_SMALL//Max size of items that this object can grap (in effect only if can_hold isn't set)

/obj/item/weapon/gripper/universal/afterattack(atom/target, mob/living/user, flag, params)

	if(!target || !flag) //Target is invalid or we are not adjacent.
		return

	//There's some weirdness with items being lost inside the arm. Trying to fix all cases. ~Z
	//if(!wrapped)
	//	for(var/obj/item/thing in src.contents)
	//		wrapped = thing
	//		break

	if(wrapped) //Already have an item.

		wrapped.loc = user
		//Pass the attack on to the target.
		target.attackby(wrapped,user)

		if(wrapped && src && wrapped.loc == user)
			wrapped.loc = src

		//Sanity/item use checks.

		if(!wrapped || !user)
			return

		if(wrapped.loc != src.loc)
			wrapped = null
			return

	if(istype(target,/obj/item)) //Check that we're not pocketing a mob.

		//...and that the item is not in a container.
		//if(!isturf(target.loc))
		//	return

		var/obj/item/I = target
		var/grab = 0

		if(can_hold)
			for(var/typepath in can_hold)
				if(istype(I,typepath))
					grab = 1
					break
		else if(w_class <= max_item_size)
			grab = 1
			for(var/typepath in cant_hold)
				if(istype(I,typepath))
					grab = 0
					break

		//We can grab the item, finally.
		if(grab)
			to_chat(user, "You collect \the [I].")
			I.loc = src
			wrapped = I
			return
		else
			to_chat(user, "\red Your gripper cannot hold \the [target].")

	else if(istype(target,/obj/machinery/power/apc))
		var/obj/machinery/power/apc/A = target
		if(A.opened)
			if(A.cell)
				var/grab = 0
				if(can_hold)
					for(var/typepath in can_hold)
						if(istype(A.cell,typepath))
							grab = 1
							break
				else if(w_class <= max_item_size)
					grab = 1
					for(var/typepath in cant_hold)
						if(istype(A.cell,typepath))
							grab = 0
							break
				if(grab)
					wrapped = A.cell

					A.cell.add_fingerprint(user)
					A.cell.updateicon()
					A.cell.loc = src
					A.cell = null

					A.charging = 0
					A.update_icon()

					user.visible_message("\red [user] removes the power cell from [A]!", "You remove the power cell.")
				else
					to_chat(user, "\red Your gripper cannot hold \the [A.cell].")