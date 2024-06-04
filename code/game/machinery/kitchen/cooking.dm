#define COOKING_STATE_END 1
#define COOKING_STATE_BURN 2
#define COOKING_STATE_FIRE 3

/datum/component/cooking
	dupe_mode = COMPONENT_DUPE_UNIQUE

	///structure storing the component
	var/obj/structure/source_atom
	///External factors that may be stopping the item from cooking
	var/functioning = FALSE
	///Whether the machine is currently making food
	var/operating = FALSE
	///Whether the machine burnt the last recipe
	var/burnt = FALSE
	///Whether the machine is actively burning down
	var/on_fire = FALSE
	///Whether the machine are in the process of cooking something
	var/cooking_state = FALSE

	///The datum of the recipe selected
	var/datum/recipe/selected_recipe
	///The food item created by the recipe
	var/obj/item/result
	///The person who cooked the food
	var/datum/weakref/chef
	///The time that the recipe is supposed to start
	var/cook_time_left

	///What categories of food can be cooked from it
	var/cooking_flags
	///A multiplier on how long a recipe takes to cook
	var/speed_multi = 1
	///Whether the cooking will make noise and messages
	var/silent_cooking = FALSE
	///The sound file played when the machine starts cooking
	var/cooking_start_sound
	///The sound file played when the machine finishes cooking
	var/cooking_end_sound

	///What items will be used to cook with
	var/list/ingredients = list()

	///All the recipes that can be cooked
	var/global/list/datum/recipe/available_recipes

/datum/component/cooking/Initialize(cooking_flags, ...)
	. = ..()
	if(!isStructure(parent))
		return COMPONENT_INCOMPATIBLE
	if(!cooking_flags)
		return COMPONENT_INCOMPATIBLE

	source_atom = parent
	src.cooking_flags = cooking_flags

	RegisterSignal(source_atom, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(source_atom, COMSIG_ATOM_CLICKED, PROC_REF(interact_with))
	RegisterSignal(source_atom, COMSIG_STRUCTURE_ATTACKBY, PROC_REF(attempt_add_ingredients))
	RegisterSignal(source_atom, COMSIG_STRUCTURE_PRE_TOGGLE_ANCHOR, PROC_REF(check_wrenchability))
	START_PROCESSING(SSobj, src)
	source_atom.update_icon(source_atom, src)

	if(available_recipes)
		return

	initialize_recipes()

/datum/component/cooking/Destroy(force, silent)
	for(var/i in 1 to ingredients) //dump all the ingredients when destroyed
		var/obj/ingredient = remove_last_ingredient() //not delete, so you cant destroy important stuff in there
		ingredient.forceMove(get_turf(source_atom))

	result = null
	selected_recipe = null
	source_atom = null
	chef = null
	. = ..()

///Set the global list of all available recipes
/datum/component/cooking/proc/initialize_recipes()
	if(available_recipes) //if called manually, delete the current list
		QDEL_NULL_LIST(available_recipes)

	available_recipes = new
	for(var/datum/recipe/new_recipe as anything in (typesof(/datum/recipe)-/datum/recipe))
		if(new_recipe == initial(new_recipe.abstract_type)) //abstract recipe
			continue

		available_recipes += new new_recipe

///Adds examine text to the machine
/datum/component/cooking/proc/on_examine(source, mob/user, list/examine_text)
	SIGNAL_HANDLER
	if(!ishuman(user))
		return

	if(!functioning)
		examine_text += "It is off."
		return

	if(operating)
		examine_text += "It is currently making something."

	var/food_selection = ""
	var/chem_selection = ""
	for(var/atom/food in ingredients)
		if(food_selection != "")
			food_selection += ", "
		food_selection += "\a [food]"
		var/chemicals = food.reagents?.get_reagents_and_amount()
		if(chemicals)
			if(chem_selection != "")
				chem_selection += ", "
			chem_selection += chemicals

	if(food_selection)
		examine_text += "It has [food_selection]."
	if(skillcheck(user, SKILL_DOMESTIC, SKILL_DOMESTIC_MASTER))
		if(chem_selection)
			examine_text += "It has [chem_selection]."

///Prevents the machine from being unwrenched if there is something in it
/datum/component/cooking/proc/check_wrenchability(source, obj/item/wrench, mob/user)
	SIGNAL_HANDLER

	if(!(functioning || operating || ingredients.len)) //dont unanchor if theres something in there, no bottomless crates
		return
	to_chat(user, SPAN_WARNING("You fail to unanchor [source]."))
	return COMPONENT_CANCEL_TOGGLE_ANCHOR

///Leads to other effects of clicking the machine
/datum/component/cooking/proc/interact_with(source, mob/user, proximity, list/mods)
	SIGNAL_HANDLER
	if(!proximity)
		return

	if((mods[ALT_CLICK]) || (mods[SHIFT_CLICK] && !mods[MIDDLE_CLICK])) //do the normal things if theres the standard click mods
		return

	if(!ishuman(user))
		return

	if(!source_atom.anchored)
		to_chat(user, SPAN_NOTICE("You cannot interact with [source] while it is unanchored."))
		return

	if(mods[CTRL_CLICK]) //Ctrl click to toggle on / off
		toggle_functioning(user)
		return COMPONENT_ATOM_OVERRIDE_CLICK

	if(!functioning)
		return

	switch(user.a_intent)
		if(INTENT_HELP)
			return //continues to attempt_add_ingredients()

		if(INTENT_DISARM)
			start_cooking(user)

		if(INTENT_GRAB)
			extra_functionality(user)

		if(INTENT_HARM)
			remove_ingredients(user)

	return COMPONENT_ATOM_OVERRIDE_CLICK

///Toggles whether the machine can be used for cooking
/datum/component/cooking/proc/toggle_functioning(mob/user)
	if(cooking_state)
		operating = !operating
		to_chat(user, SPAN_NOTICE("You [operating ? "start" : "stop"] [source_atom]."))

		return
	functioning = !functioning
	to_chat(user, SPAN_NOTICE("You [functioning ? "enable" : "disable"] [source_atom]."))
	send_state_signals()

#define COOLDOWN_COOKING_ITEM_TRANSFER "cooking_item_transfer"
///Add an ingredient to the machines contents and ingredients list from the mobs hand
/datum/component/cooking/proc/attempt_add_ingredients(source, obj/item/attacking_item, mob/user)
	SIGNAL_HANDLER

	if(!functioning)
		return

	if(operating)
		to_chat(user, SPAN_NOTICE("You shouldn't put ingredients in [source] while it is on."))
		return

	if(attacking_item.flags_item & ITEM_ABSTRACT)
		return

	if(istype(attacking_item, /obj/item/stack))
		var/obj/item/stack/stack = attacking_item
		if(stack.amount != 1)
			to_chat(user, SPAN_NOTICE("You can only put one of [stack] in [source] at a time."))
			return

	if(TIMER_COOLDOWN_CHECK(user, COOLDOWN_COOKING_ITEM_TRANSFER))
		to_chat(user, SPAN_WARNING("You are attempting to put ingredients in [source] too fast."))
		return

	if(!user.drop_inv_item_to_loc(attacking_item, source))
		to_chat(user, SPAN_NOTICE("You fail to put [attacking_item] in [source]."))
		return

	if(SEND_SIGNAL(source_atom, COMSIG_COOKING_MACHINE_ATTEMPT_ADD, src, user, attacking_item) & COMPONENT_COOKING_MACHINE_CANCEL_ADD) //Something special blocked it
		return

	ingredients += attacking_item
	user.visible_message("[user] adds [attacking_item] to [source].", "You add [attacking_item] to [source].")
	log_admin("[key_name(user)] has added [attacking_item] to [source].") //If you cook the wrong item I will come for you
	TIMER_COOLDOWN_START(user, COOLDOWN_COOKING_ITEM_TRANSFER, 1 SECONDS)
	send_state_signals()
	return COMPONENT_NO_AFTERATTACK

///Turn the ingredients into food
/datum/component/cooking/proc/start_cooking(mob/user)
	if(cooking_state)
		to_chat(user, SPAN_WARNING("Something is already being made."))
		return

	var/datum/recipe/new_recipe = select_recipe(available_recipes, src, user)
	if(!new_recipe)
		to_chat(user, SPAN_WARNING("There are no valid recipes that can be made with these ingredients."))
		return
	var/time_to_cook = new_recipe.time * speed_multi

	if(!silent_cooking)
		if(cooking_start_sound)
			playsound(source_atom, cooking_start_sound, 25)
		source_atom.visible_message(SPAN_NOTICE("[source_atom] activates and begins cooking something."))

	chef = WEAKREF(user)
	cook_time_left = time_to_cook
	selected_recipe = new_recipe
	cooking_state = COOKING_STATE_END
	operating = TRUE
	send_state_signals()

/datum/component/cooking/proc/finish_cooking()
	if(!cooking_state)
		return

	result = selected_recipe.make(chef, src)

	if(selected_recipe != select_recipe(available_recipes, src, chef))
		burnt_cooking(chef, result)
		return

	if(!silent_cooking)
		if(cooking_end_sound)
			playsound(source_atom, cooking_end_sound, 25)
		source_atom.visible_message(SPAN_NOTICE("[source_atom] finishes cooking [result]."))

	ingredients += result
	cooking_state = COOKING_STATE_BURN
	cook_time_left = selected_recipe.time / 2
	send_state_signals()

/datum/component/cooking/proc/burnt_cooking()
	if(!cooking_state)
		return

	if(!(result in ingredients))
		return

	source_atom.visible_message(SPAN_WARNING("Is something burning?"))

	burnt = TRUE
	cooking_state = COOKING_STATE_FIRE
	cook_time_left = selected_recipe.time / 2

///Any extra functions that the machine might have
/datum/component/cooking/proc/extra_functionality(mob/user)
	return

///Put the ingredients into the user's hands or the floor
/datum/component/cooking/proc/remove_ingredients(mob/user)
	if(!ingredients.len)
		to_chat(user, SPAN_NOTICE("There are no ingredients for you to remove."))
		return

	if(TIMER_COOLDOWN_CHECK(user, COOLDOWN_COOKING_ITEM_TRANSFER))
		to_chat(user, SPAN_WARNING("You are attempting to remove ingredients from [source_atom] too fast."))
		return

	var/obj/last_ingredient = remove_last_ingredient()
	if(!last_ingredient)
		to_chat(user, SPAN_NOTICE("You fail to remove a ingredient."))
		return

	if(!user.put_in_hands(last_ingredient))
		last_ingredient.forceMove(get_turf(source_atom))
	to_chat(user, SPAN_NOTICE("You remove [last_ingredient] from [source_atom]."))
	log_admin("[key_name(user)] has removed [last_ingredient] from [source_atom].")
	TIMER_COOLDOWN_START(user, COOLDOWN_COOKING_ITEM_TRANSFER, 1 SECONDS)
	send_state_signals()

//Remove ingredients from the machine, return the ingredient
/datum/component/cooking/proc/remove_last_ingredient()
	var/obj/last_ingredient = ingredients[ingredients.len]

	if(QDELETED(last_ingredient)) //Shouldnt be possible, but just incase someone breaks it, remove it
		ingredients -= last_ingredient
		return

	ingredients -= last_ingredient
	return last_ingredient

#undef COOLDOWN_COOKING_ITEM_TRANSFER

/datum/component/cooking/proc/send_state_signals()
	SEND_SIGNAL(source_atom, COMSIG_COOKING_MACHINE_STATE, src)

/datum/component/cooking/process(delta_time)
	if(!operating)
		return

	if(isnull(cook_time_left))
		return

	if(cooking_state < COOKING_STATE_END || cooking_state > COOKING_STATE_FIRE)
		selected_recipe = null
		cook_time_left = null
		result = null
		chef = null
		cooking_state = FALSE
		operating = FALSE
		on_fire = FALSE
		return

	if(on_fire && !cook_time_left)
		new /obj/flamer_fire(get_turf(source_atom))
		cook_time_left = 30
		return

	if(cook_time_left <= 0)
		switch(cooking_state)
			if(COOKING_STATE_END)
				finish_cooking()
			if(COOKING_STATE_BURN)
				burnt_cooking()
			if(COOKING_STATE_FIRE)
				on_fire = TRUE
		return

	if(cook_time_left)
		cook_time_left -= delta_time
