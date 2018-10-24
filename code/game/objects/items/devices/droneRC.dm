/obj/item/device/droneRC //drone remote control
	name = "personal AI device"
	icon = 'icons/obj/pda.dmi'
	icon_state = "pai"
	item_state = "electronic"
	w_class = 2.0
	slot_flags = SLOT_BELT
	origin_tech = "programming=3;engineering=1;syndicate=2"
	var/list/requested_candidates = list()
	var/mob/living/owner = null
	var/used = FALSE
	var/TC_cost = 0

/obj/item/device/droneRC/atom_init()
	. = ..()
	overlays += "pai-off"

/obj/item/device/droneRC/attack_self(mob/user)
	if (!in_range(src, user))
		return
	if(used)
		to_chat(user, "The teleporter is out of power.")
		return
	owner = user
	var/list/drone_candidates = get_candidates(ROLE_PAI)
	if(drone_candidates.len > 0)
		requested_candidates.Cut()
		used = TRUE
		TC_cost = 0
		to_chat(user, "<span class='notice'>Seatching for available drone personality. Please wait 30 seconds...</span>")
		for(var/client/C in drone_candidates)
			INVOKE_ASYNC(src, .proc/request_player, C)
		addtimer(CALLBACK(src, .proc/stop_search), 300)
	else
		to_chat(user, "<span class='notice'>Unable to connect to Syndicate Command. Please wait and try again later or use the teleporter on your uplink to get your points refunded.</span>")

/obj/item/device/droneRC/proc/request_player(client/C)
	if(!C)
		return
	var/response = alert(C, "Syndicate requesting a personality for a syndicate borg. Would you like to play as one?", "Syndicate borg request", "Yes", "No")
	if(!C)
		return		//handle logouts that happen whilst the alert is waiting for a respons.
	if(response == "Yes")
		requested_candidates += C

/obj/item/device/droneRC/proc/stop_search()
	if(requested_candidates.len > 0)
		var/client/C = pick(requested_candidates)
		spawn_antag(C, get_turf(src.loc), "syndiedrone")
	else
		used = FALSE
		visible_message("\blue Unable to connect to Syndicate Command. Please wait and try again later or use the teleporter on your uplink to get your points refunded.")

/obj/item/device/droneRC/proc/spawn_antag(client/C, turf/T, type = "")
	var/datum/effect/effect/system/spark_spread/S = new /datum/effect/effect/system/spark_spread
	S.set_up(4, 1, src)
	S.start()
	var/mob/living/silicon/robot/drone/syndi/D = new /mob/living/silicon/robot/drone/syndi(T)
	D.key = C.key
	D.set_master(owner)
	ticker.mode.syndicates += D.mind
	ticker.mode.update_synd_icons_added(D.mind)
	D.mind.special_role = "syndicate"
	D.faction = "syndicate"