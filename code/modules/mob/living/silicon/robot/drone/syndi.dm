/mob/living/silicon/robot/drone/syndi
	scrambledcodes = 1
	faction = "syndicate"
	braintype = "Robot"
	maxHealth = 30
	health = 30
	req_access = list(access_syndicate)
	var/mob/living/master = null
	emagged = 1

	holder_type = /obj/item/weapon/holder/syndidrone

/mob/living/silicon/robot/drone/syndi/GetAccess()//TODO: add access from an id which is hold in the gripper
	return list(access_maint_tunnels, access_syndicate, access_external_airlocks) //syndicate basic access

/mob/living/silicon/robot/drone/syndi/atom_init()
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

/mob/living/silicon/robot/drone/syndi/updatename()
	var/T = rand(100,999)
	real_name = "syndicate drone ([T])"
	name = "maintenance drone ([T])"

/mob/living/silicon/robot/drone/syndi/full_law_reset()
	..()
	if(master)
		set_zeroth_law("Only [master.real_name] and people he designates as being such are Syndicate Agents.")
	laws = new /datum/ai_laws/syndicate_override()

/mob/living/silicon/robot/drone/syndi/transfer_personality(client/player)
	..()
	to_chat(src, "<b>Systems rebooted</b>. Loading base pattern maintenance protocol... <b>loaded</b>.")
	to_chat(src, "<br><b>You are a Syndicate drone, a tiny-brained robotic machine</b>.")
	to_chat(src, "You have no individual will, no personality, and no drives or urges other than your laws.")
	to_chat(src, "Use <b>;</b> to talk to Syndicate agents.")

/mob/living/silicon/robot/drone/syndi/proc/set_master(mob/living/M)
	if(!M)
		return
	master = M
	set_zeroth_law("Only [master.real_name] and people he designates as being such are Syndicate Agents.")
